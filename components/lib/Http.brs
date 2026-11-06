' VLTV Play - Roku | Chamadas HTTP (só dentro de Tarefas: ficam esperando a resposta).

function novaTransferencia(url as String, cabecalhos as Object) as Object
    x = CreateObject("roUrlTransfer")
    x.SetUrl(url)
    x.SetCertificatesFile("common:/certs/ca-bundle.crt")
    x.InitClientCertificates()
    x.EnableEncodings(true)
    x.RetainBodyOnError(true)
    x.AddHeader("User-Agent", "VLTV-Roku")
    if cabecalhos <> invalid
        for each k in cabecalhos
            x.AddHeader(k, cabecalhos[k])
        end for
    end if
    return x
end function

' Devolve { ok, status, texto }. status 0 = sem resposta (rede ou tempo).
function httpSync(url as String, metodo as String, corpo as String, cabecalhos as Object, ms as Integer) as Object
    porta = CreateObject("roMessagePort")
    x = novaTransferencia(url, cabecalhos)
    x.SetMessagePort(porta)
    if metodo = "POST"
        iniciou = x.AsyncPostFromString(corpo)
    else
        iniciou = x.AsyncGetToString()
    end if
    if not iniciou then return { ok: false, status: 0, texto: "" }
    msg = Wait(ms, porta)
    if msg = invalid
        x.AsyncCancel()
        return { ok: false, status: 0, texto: "" }
    end if
    if Type(msg) = "roUrlEvent"
        codigo = msg.GetResponseCode()
        if codigo < 0 then codigo = 0
        return { ok: codigo >= 200 and codigo < 300, status: codigo, texto: msg.GetString() }
    end if
    return { ok: false, status: 0, texto: "" }
end function

' GET que já converte o JSON. json = invalid se a resposta não for JSON.
function httpJson(url as String, ms as Integer) as Object
    r = httpSync(url, "GET", "", invalid, ms)
    r.json = invalid
    if r.ok and r.texto <> "" then r.json = ParseJson(r.texto)
    return r
end function

' Baixa direto para um arquivo (listas grandes). Devolve { ok, status }.
function httpArquivo(url as String, caminho as String, ms as Integer) as Object
    porta = CreateObject("roMessagePort")
    x = novaTransferencia(url, invalid)
    x.SetMessagePort(porta)
    if not x.AsyncGetToFile(caminho) then return { ok: false, status: 0 }
    msg = Wait(ms, porta)
    if msg = invalid
        x.AsyncCancel()
        return { ok: false, status: 0 }
    end if
    if Type(msg) = "roUrlEvent"
        codigo = msg.GetResponseCode()
        if codigo < 0 then codigo = 0
        return { ok: codigo >= 200 and codigo < 300, status: codigo }
    end if
    return { ok: false, status: 0 }
end function
