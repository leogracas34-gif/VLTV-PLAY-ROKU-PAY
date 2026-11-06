' VLTV Play - Roku | Tarefa de login e licença.
'   op "entrar":   ctx { modo, user, pass, codigo, servidor, m3u, dnsPreferido } -> { estado, base, info, teste, painel, nome, lic }
'   op "login":    só o login no painel (autenticarLista)
'   op "licnova":  licença para lista comum (licVerificar(""))
'   op "licenca":  confere a licença da TV -> { estado, codigo, dias, pagar_url, ... }
'   op "rokupay":  ctx { transacao, produto } -> licença ativada pela VPS após compra no Roku Pay
'   op "informar": ctx { codigo } avisa a VPS qual lista de parceiro está em uso -> { ok }
'   op "visual":   campanha e cores remotas (/lg/config)
sub init()
    m.top.functionName = "executar"
end sub

sub executar()
    op = m.top.op
    ctx = m.top.ctx
    if ctx = invalid then ctx = {}
    if op = "entrar" then
        m.top.result = autenticar(ctx)
    else if op = "login" then
        ' Só o login no painel (a licença da TV é conferida em outra tarefa, ao mesmo tempo).
        m.top.result = autenticarLista(ctx)
    else if op = "licnova" then
        ' Licença para uma lista que NÃO é de parceiro (avisa a VPS que não há código de parceiro).
        m.top.result = licVerificar("")
    else if op = "licenca" then
        m.top.result = licVerificar()
    else if op = "informar" then
        m.top.result = { ok: licInformarParceiro(sv(ctx.codigo)) }
    else if op = "rokupay" then
        m.top.result = licRokuComprar(sv(ctx.transacao), sv(ctx.produto))
    else if op = "guarda" then
        m.top.result = guardaLicenca()
    else if op = "visual" then
        r = httpSync(sv(cfg().licenca) + "/lg/config", "GET", "", invalid, 8000)
        j = invalid
        if r.ok then j = ParseJson(r.texto)
        if j = invalid or not isAA(j) then j = {}
        m.top.result = j
    end if
end sub

' Regra da licença: lista de código de parceiro entra sempre. Qualquer outra lista só entra se a licença da TV
' estiver valendo (teste de 7 dias ou ativa); senão volta { estado: "sem_licenca" } e o app mostra a ativação.
function autenticar(ctx as Object) as Object
    if sv(ctx.modo) = "parceiro" then return autenticarLista(ctx)
    ' Informa à VPS que ESTA lista não é de parceiro (senão ela ainda responde pelo código da lista anterior).
    antigo = licParceiroAtual()
    lic = licVerificar("")
    if liberaListaComum(lic) then return autenticarLista(ctx)
    ' Não entrou: se a lista de parceiro em uso continua valendo, devolve o aviso dela para a VPS.
    if antigo <> "" then licInformarParceiro(antigo)
    return { estado: "sem_licenca", lic: lic }
end function

function autenticarLista(ctx as Object) as Object
    modo = sv(ctx.modo)
    user = sv(ctx.user)
    pass = sv(ctx.pass)
    tempo = 15000

    if modo = "m3u" then
        r = m3uCarregar(sv(ctx.m3u))
        if r = "ok" then return { estado: "ok" }
        if r = "tamanho" then return { estado: "m3u_grande" }
        if r = "vazia" then return { estado: "m3u_vazia" }
        return { estado: "erro" }
    end if

    if modo = "parceiro" then
        p = parceiroResolver(sv(ctx.codigo))
        if p.estado = "ok" then
            r = xtreamLogin(user, pass, p.dns, tempo)
            r.nome = p.nome
            return r
        end if
        ' Sem resposta da VPS: tenta o servidor que funcionou da última vez.
        if p.estado = "rede" and sv(ctx.dnsPreferido) <> "" then
            return xtreamLogin(user, pass, [sv(ctx.dnsPreferido)], tempo)
        end if
        if p.estado = "rede" then return { estado: "erro" }
        return { estado: p.estado }
    end if

    if modo = "xtream" then
        return xtreamLogin(user, pass, [normalizarDns(sv(ctx.servidor))], tempo)
    end if

    ' Usuário e senha do VLTV Play: sempre pelo gateway.
    return xtreamLogin(user, pass, [semBarraFinal(sv(cfg().gateway))], tempo)
end function

' Vigia (roda de tempos em tempos, em qualquer tela): confere a licença da TV e, se a lista é de parceiro, se o código continua valendo.
'   { ok, modo, lic, parceiroCaiu }
function guardaLicenca() as Object
    s = sessaoLer()
    if s = invalid then return { ok: false }
    if s.modo = "parceiro" then
        ' Lista de parceiro: o código precisa continuar ativo no painel (a licença da TV não conta).
        p = parceiroResolver(sv(s.codigo))
        if p.estado = "codigo_invalido" or p.estado = "suspenso" then
            licInformarParceiro("")
            return { ok: true, modo: s.modo, lic: licVerificar(""), parceiroCaiu: true }
        end if
        return { ok: true, modo: s.modo, lic: { estado: "trial" }, parceiroCaiu: false }
    end if
    ' Lista comum: a licença da TV precisa continuar valendo (teste ou ativa).
    return { ok: true, modo: s.modo, lic: licVerificar(""), parceiroCaiu: false }
end function
