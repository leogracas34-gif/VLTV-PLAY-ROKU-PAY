' VLTV Play - Roku | Login Xtream, código de parceiro e endereços do painel (só dentro de Tarefas).

function limparCodigoParceiro(t as String) as String
    return CreateObject("roRegex", "[^A-Z0-9]", "").ReplaceAll(UCase(t), "")
end function

' Resolve com { estado, nome, dns }.  estado: ok | codigo_invalido | suspenso | limite | rede
function parceiroResolver(codigo as String) as Object
    limpo = limparCodigoParceiro(codigo)
    if limpo = "" then return { estado: "codigo_invalido" }
    url = sv(cfg().parceiro) + "?codigo=" + urlEnc(limpo)
    r = httpSync(url, "GET", "", invalid, 6000)
    if r.status = 404 then return { estado: "codigo_invalido" }
    if r.status = 403 then return { estado: "suspenso" }
    if r.status = 429 then return { estado: "limite" }
    if not r.ok then return { estado: "rede" }
    j = ParseJson(r.texto)
    lista = []
    if j <> invalid and isAA(j) and j.ok = true and isLista(j.dns)
        for each d in j.dns
            n = normalizarDns(sv(d))
            if n <> "" then lista.Push(n)
        end for
    end if
    if lista.Count() = 0 then return { estado: "rede" }
    return { estado: "ok", nome: sv(j.nome), dns: lista }
end function

' Lê a resposta do login do painel. estado: ok | expirado | invalido | erro
function interpretarLogin(codigo as Integer, texto as String, base as String) as Object
    if codigo < 200 or codigo >= 300 then return { estado: "erro", base: base }
    j = ParseJson(texto)
    if j = invalid or not isAA(j) then return { estado: "erro", base: base }
    ui = j.user_info
    if ui = invalid or not isAA(ui) or j.server_info = invalid then return { estado: "invalido", base: base }
    if sv(ui.auth) = "0" then return { estado: "invalido", base: base }
    situacao = LCase(sv(ui.status))
    painel = sv(ui.vltv_painel)
    if situacao = "expired" or situacao = "disabled"
        t = LCase(sv(ui.is_trial))
        return { estado: "expirado", base: base, info: ui, teste: (t = "1" or t = "true"), painel: painel }
    end if
    return { estado: "ok", base: base, info: ui, painel: painel }
end function

' Testa todos os servidores ao mesmo tempo; o primeiro que responder (ok ou vencido) vale.
function xtreamLogin(user as String, pass as String, servidores as Object, ms as Integer) as Object
    if servidores.Count() = 0 then return { estado: "erro" }
    porta = CreateObject("roMessagePort")
    pedidos = {}
    for each base in servidores
        url = base + "/player_api.php?username=" + urlEnc(user) + "&password=" + urlEnc(pass)
        x = novaTransferencia(url, invalid)
        x.SetMessagePort(porta)
        if x.AsyncGetToString()
            pedidos[sv(x.GetIdentity())] = { x: x, base: base }
        end if
    end for
    pendentes = pedidos.Count()
    viuInvalido = false
    fim = nowMs() + ms
    resultado = invalid
    while pendentes > 0 and resultado = invalid
        restante = fim - nowMs()
        if restante <= 0 then exit while
        msg = Wait(Int(restante), porta)
        if msg = invalid then exit while
        if Type(msg) = "roUrlEvent"
            p = pedidos[sv(msg.GetSourceIdentity())]
            if p <> invalid
                res = interpretarLogin(msg.GetResponseCode(), msg.GetString(), p.base)
                if res.estado = "ok" or res.estado = "expirado"
                    resultado = res
                else
                    if res.estado = "invalido" then viuInvalido = true
                    pendentes = pendentes - 1
                end if
            end if
        end if
    end while
    for each k in pedidos
        pedidos[k].x.AsyncCancel()
    end for
    if resultado <> invalid then return resultado
    if viuInvalido then return { estado: "invalido" }
    return { estado: "erro" }
end function

' Chamada ao painel (player_api.php) já convertida. Devolve invalid se falhar.
function xtreamPedir(s as Object, acao as String, extra as String, ms as Integer) as Dynamic
    url = sv(s.dns) + "/player_api.php?username=" + urlEnc(sv(s.user)) + "&password=" + urlEnc(sv(s.pass)) + "&action=" + acao + extra
    r = httpSync(url, "GET", "", invalid, ms)
    if not r.ok or r.texto = "" then return invalid
    return ParseJson(r.texto)
end function

function comoListaXt(v as Dynamic) as Object
    if isLista(v) then return v
    return []
end function

' Endereço do vídeo. tipo: "live" | "movie" | "series". ext: "m3u8", "ts", "mp4"... ("" = sem extensão)
function urlStream(s as Object, tipo as String, id as String, ext as String) as String
    u = sv(s.dns) + "/" + tipo + "/" + urlEnc(sv(s.user)) + "/" + urlEnc(sv(s.pass)) + "/" + id
    if ext <> "" then u = u + "." + ext
    return u
end function

' ── Formato dos canais ao vivo ──────────────────────────────────────
' Igual ao app da LG: tenta primeiro o .ts (o sinal abre bem mais rápido que o .m3u8); se não abrir, cai no .m3u8.
' Depois de 2 falhas seguidas do .ts, esta TV passa a começar pelo .m3u8 (o canal não demora a abrir).
' Para forçar o .m3u8 sempre, coloque "formatoLive": "m3u8" no config.json.
function liveFmtPreferido() as String
    ' Padrão: .m3u8 (HLS), que na Roku toca com imagem. O .ts cru às vezes toca só o áudio e,
    ' como o player já fica "playing", o plano B nunca dispara. Para voltar ao .ts primeiro,
    ' coloque "formatoLive": "ts" no config.json.
    if LCase(sv(cfg().formatoLive)) = "ts" and regGet("live_fmt") <> "m3u8" then return "ts"
    return "m3u8"
end function

function liveFmtOutro(f as String) as String
    if f = "ts" then return "m3u8"
    return "ts"
end function

sub liveTsFalhou()
    n = Val(regGet("live_ts_falhas")) + 1
    if n >= 2 then
        regSet("live_fmt", "m3u8")
        regSet("live_ts_falhas", "")
    else
        regSet("live_ts_falhas", Str(n).Trim())
    end if
end sub

sub liveTsFuncionou()
    if regGet("live_ts_falhas") <> "" then regSet("live_ts_falhas", "")
end sub
