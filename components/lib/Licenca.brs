' VLTV Play - Roku | Licença da TV: teste grátis de 7 dias, ativação anual e parceiro (só dentro de Tarefas).
' A TV se apresenta à VPS (/lg/register) e recebe o estado: trial | active | expired | blocked.
' Regras:
'   - Lista de código de parceiro: sempre entra ("Ativo parceiro" no painel), sem teste nem vencimento.
'   - Qualquer outra lista: precisa de licença valendo (teste de 7 dias contado desde a 1ª abertura, ou ativa).

' O servidor só aceita device_id no formato "uid-" ou "mac-" + letras/números (8 a 64). Por isso "uid-roku" + ID da Roku sem traços.
function licIdentidade() as Object
    id = regGet("dev_id")
    if Left(id, 8) <> "uid-roku" then id = ""
    if id = "" then
        di = CreateObject("roDeviceInfo")
        base = sv(di.GetChannelClientId())
        if base = "" then base = sv(di.GetRIDA())
        rx = CreateObject("roRegex", "[^a-zA-Z0-9]", "")
        base = LCase(rx.ReplaceAll(base, ""))
        if Len(base) < 8 then
            base = ""
            for i = 1 to 20
                base = base + Mid("abcdefghijklmnopqrstuvwxyz0123456789", Rnd(36), 1)
            end for
        end if
        id = Left("uid-roku" + base, 64)
        regSet("dev_id", id)
    end if
    return { id: id, mac: "" }
end function

function licModelo() as String
    di = CreateObject("roDeviceInfo")
    return "Roku " + sv(di.GetModelDisplayName()) + " (" + sv(di.GetModel()) + ")"
end function

function licCache() as Dynamic
    return regJson("licenca")
end function

function licChamar(metodo as String, caminho as String, corpo as Dynamic, token as String) as Object
    cab = {}
    texto = ""
    if corpo <> invalid
        cab["Content-Type"] = "application/json"
        texto = FormatJson(corpo)
    end if
    if token <> "" then cab["Authorization"] = "Bearer " + token
    r = httpSync(sv(cfg().licenca) + caminho, metodo, texto, cab, 6000)
    j = invalid
    if r.texto <> "" then j = ParseJson(r.texto)
    if j = invalid or not isAA(j) then j = {}
    return { status: r.status, json: j }
end function

function licGuardar(j as Object, id as String) as Object
    exp = iv(j.expira_em)
    e = {
        estado: sv(j.estado),
        vitalicio: (j.vitalicio = true) or (exp - nowSec() > 315360000),
        codigo: sv(j.codigo),
        dias: iv(j.dias),
        expira_em: exp
    }
    regJsonSet("licenca", { e: e, token: sv(j.token), id: id, em: nowSec() })
    return e
end function

' O aviso de parceiro só conta como entregue quando a VPS responde 200 (senão é reenviado na próxima consulta).
function licParceiroAtual() as String
    return regGet("lic_parc")
end function

' Resolve { estado: trial|active|expired|blocked|erro, codigo, dias, pagar_url, expira_em, vitalicio, texto }
' forcado (opcional): código a informar nesta consulta. "" = "a lista que vai entrar NÃO é de parceiro".
' Sem ele, usa o código da lista que estava em uso (que pode estar velho ao trocar de lista).
function licVerificar(forcado = invalid as Dynamic) as Object
    ident = licIdentidade()
    c = licCache()
    parc = licParceiroAtual()
    if forcado <> invalid then parc = UCase(sv(forcado))

    if c <> invalid and sv(c.token) <> "" and sv(c.id) = ident.id then
        r = licChamar("GET", "/lg/status?parceiro=" + urlEnc(parc), invalid, sv(c.token))
        if r.status = 200 and r.json.estado <> invalid then
            licConfirmou(parc)
            return licGuardar(r.json, ident.id)
        else if r.status = 401 or r.status = 404 then
            return licRegistrar(ident, parc, c)
        end if
        return licOffline(c, ident)
    end if
    return licRegistrar(ident, parc, c)
end function

' O aviso só conta como entregue se for do mesmo código que está guardado como "em uso".
sub licConfirmou(parc as String)
    if parc = licParceiroAtual() then regSet("lic_parc_ok", "1")
end sub

function licRegistrar(ident as Object, parc as String, c as Dynamic) as Object
    corpo = { device_id: ident.id, mac: ident.mac, model: licModelo(), version: sv(cfg().versao), parceiro: parc }
    r = licChamar("POST", "/lg/register", corpo, "")
    if r.status = 200 and r.json.estado <> invalid then
        licConfirmou(parc)
        return licGuardar(r.json, ident.id)
    end if
    if r.status >= 500 or r.status = 0 then return licOffline(c, ident)
    return { estado: "erro", texto: sv(r.json.error) }
end function

' Sem resposta do servidor: confia no último estado por até 3 dias (só trial/ativa que não venceu).
function licOffline(c as Dynamic, ident as Object) as Object
    if c <> invalid and c.e <> invalid and sv(c.id) = ident.id then
        idade = nowSec() - iv(c.em)
        venceu = iv(c.e.expira_em) > 0 and iv(c.e.expira_em) < nowSec()
        if idade < 259200 and not venceu and (c.e.estado = "trial" or c.e.estado = "active") then return c.e
    end if
    return { estado: "erro" }
end function

' Avisa a VPS qual lista de parceiro a TV usa agora ("" = lista que não é de parceiro).
' Devolve true se a VPS confirmou (200). Em falha fica pendente e a próxima consulta reenvia.
function licInformarParceiro(codigo as String) as Boolean
    c = UCase(codigo)
    regSet("lic_parc", c)
    regSet("lic_parc_ok", "0")
    ident = licIdentidade()
    cache = licCache()
    if cache <> invalid and sv(cache.token) <> "" then
        r = licChamar("GET", "/lg/status?parceiro=" + urlEnc(c), invalid, sv(cache.token))
        if r.status = 200 and r.json.estado <> invalid then
            licGuardar(r.json, ident.id)
            regSet("lic_parc_ok", "1")
            return true
        end if
    end if
    e = licVerificar()
    return e.estado <> "erro" and regGet("lic_parc_ok") = "1"
end function

function liberaListaComum(lic as Dynamic) as Boolean
    if lic = invalid then return false
    return lic.estado = "active" or lic.estado = "trial"
end function

' "Teste grátis: 5 dias (até 12/10/2026)" ou "Ativa até 07/10/2027"
function licTextoCurto(e as Dynamic, ehParceiro as Boolean) as String
    if ehParceiro then return "Ativo"
    if e = invalid or not isAA(e) or sv(e.estado) = "" then return ""
    if e.estado = "active" then
        if sv(e.vitalicio) = "true" then return "Vitalícia (sem vencimento)"
        return "Ativa até " + dataBr(e.expira_em)
    end if
    dias = iv(e.dias)
    palavra = " dias"
    if dias = 1 then palavra = " dia"
    return "Teste grátis: " + Str(dias).Trim() + palavra + " (até " + dataBr(e.expira_em) + ")"
end function

' Avisos da Home: licença do app e plano de canais (faltam <= limite dias).
function licAvisos(e as Dynamic, ehParceiro as Boolean, expPlano as Dynamic) as Object
    lista = []
    limite = iv(cfg().avisoDias)
    if limite <= 0 then limite = 7
    temLic = false
    if e <> invalid then
        if isAA(e) then temLic = true
    end if
    if temLic and not ehParceiro then
        expira = iv(e.expira_em)
        vitalicio = (sv(e.vitalicio) = "true")
        if not vitalicio and expira > 0 then
            d = diasAte(expira)
            if d <= limite and d >= 0 then
                quando = "em " + Str(d).Trim() + " dias"
                if d = 0 then quando = "hoje"
                if d = 1 then quando = "amanhã"
                if sv(e.estado) = "trial" then
                    lista.Push("Seu teste grátis do aplicativo termina " + quando)
                else
                    lista.Push("A licença do aplicativo vence " + quando)
                end if
            end if
        end if
    end if
    n = iv(expPlano)
    if n > 0 then
        p = diasAte(n)
        if p < 0 then
            lista.Push("O plano de canais, filmes e séries venceu. Fale com o seu provedor.")
        else if p <= limite then
            quando = "em " + Str(p).Trim() + " dias"
            if p = 0 then quando = "hoje"
            if p = 1 then quando = "amanhã"
            lista.Push("O plano de canais, filmes e séries vence " + quando)
        end if
    end if
    return lista
end function

' ── Roku Pay ────────────────────────────────────────────────────────
' Depois da compra no Roku Pay, manda o transactionId para a VPS. A VPS confirma com a Roku (validate-transaction,
' usando a chave secreta que fica só na VPS) e ativa a licença desta TV. Devolve o mesmo formato de licVerificar().
function licRokuComprar(transacao as String, produto as String) as Object
    ident = licIdentidade()
    c = licCache()
    if c = invalid or sv(c.token) = "" then
        licRegistrar(ident, licParceiroAtual(), c)
        c = licCache()
    end if
    if c = invalid or sv(c.token) = "" then return { estado: "erro", texto: "sem_token" }
    corpo = { device_id: ident.id, transaction_id: transacao, product_code: produto, versao: sv(cfg().versao) }
    r = licChamar("POST", "/lg/roku/comprar", corpo, sv(c.token))
    if r.status = 200 and r.json.estado <> invalid then return licGuardar(r.json, ident.id)
    if r.status = 0 or r.status >= 500 then return { estado: "erro", texto: "rede" }
    return { estado: "recusada", texto: sv(r.json.error) }
end function
