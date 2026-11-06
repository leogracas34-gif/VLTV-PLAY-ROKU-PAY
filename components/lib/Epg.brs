' VLTV Play - Roku | Guia de programação (EPG): limpa o que o painel mandou e separa "agora" e "próximos".

' Texto do painel ("AAAA-MM-DD HH:MM:SS") não traz fuso: vale como horário local da TV.
function lerTempoEpg(valor as Dynamic, texto as Dynamic) as Integer
    s = sv(valor).Trim()
    if Len(s) >= 9 and Len(s) <= 13 and CreateObject("roRegex", "^\d+$", "").IsMatch(s) then
        n = Val(s)
        if n > 99999999999 then n = Int(n / 1000)
        if n > 1000000000 then return Int(n)
    end if
    t = sv(texto).Trim()
    r = CreateObject("roRegex", "^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})(?::(\d{2}))?", "").Match(t)
    if r.Count() > 5 then
        seg = "00"
        if r.Count() > 6 and r[6] <> "" then seg = r[6]
        d = CreateObject("roDateTime")
        d.FromISO8601String(r[1] + "-" + r[2] + "-" + r[3] + "T" + r[4] + ":" + r[5] + ":" + seg + "Z")
        return d.AsSeconds() + d.GetTimeZoneOffset() * 60
    end if
    return 0
end function

' Devolve a lista limpa: [{ titulo, descricao, iniTs, fimTs, inicio, fim }]
function normalizarEpg(itens as Object) as Object
    lista = []
    for each p in itens
        if isAA(p) then
            ini = lerTempoEpg(p.start_timestamp, p.start)
            fim = lerTempoEpg(p.stop_timestamp, sv(p.end) + sv(p.stop))
            if ini > 0 then
                descartar = false
                if fim > 0 and (fim <= ini or fim - ini > 43200) then
                    if fim - ini > 43200 then descartar = true
                    fim = 0
                end if
                if not descartar then
                    lista.Push({ titulo: b64(sv(p.title)), descricao: b64(sv(p.description)), iniTs: ini, fimTs: fim })
                end if
            end if
        end if
    end for
    lista.SortBy("iniTs")

    limpa = []
    for each p in lista
        n = limpa.Count()
        if n > 0 and limpa[n - 1].iniTs = p.iniTs then
            ant = limpa[n - 1]
            if ant.titulo = "" or (p.descricao <> "" and ant.descricao = "") then limpa[n - 1] = p
        else if n > 0 and limpa[n - 1].titulo <> "" and limpa[n - 1].titulo = p.titulo and (limpa[n - 1].fimTs = 0 or limpa[n - 1].fimTs >= p.iniTs - 60) then
            ant = limpa[n - 1]
            if p.fimTs > 0 then ant.fimTs = p.fimTs
            if ant.descricao = "" then ant.descricao = p.descricao
        else
            limpa.Push(p)
        end if
    end for

    for i = 0 to limpa.Count() - 1
        p = limpa[i]
        if i + 1 < limpa.Count() then
            prox = limpa[i + 1]
            if p.fimTs = 0 or p.fimTs > prox.iniTs then p.fimTs = prox.iniTs
        end if
        p.inicio = horaMinuto(p.iniTs)
        p.fim = horaMinuto(p.fimTs)
    end for
    return limpa
end function

' { atual: AA|invalid, proximos: [], espera: ms até o guia mudar }
function separarEpg(lista as Object, agoraSeg as Integer) as Object
    vivos = []
    for each p in lista
        if not (p.fimTs > 0 and p.fimTs <= agoraSeg) then vivos.Push(p)
    end for
    atual = invalid
    resto = vivos
    if vivos.Count() > 0 and (vivos[0].iniTs = 0 or vivos[0].iniTs <= agoraSeg) then
        atual = vivos[0]
        resto = []
        for i = 1 to vivos.Count() - 1
            resto.Push(vivos[i])
        end for
    end if
    proximoTs = 0
    if atual <> invalid and atual.fimTs > 0 then
        proximoTs = atual.fimTs
    else if resto.Count() > 0 and resto[0].iniTs > 0 then
        proximoTs = resto[0].iniTs
    end if
    espera = 60000
    if proximoTs > 0 then espera = (proximoTs - agoraSeg + 3) * 1000
    if espera < 15000 then espera = 15000
    if espera > 300000 then espera = 300000
    return { atual: atual, proximos: resto, espera: espera }
end function

' "Amanhã 02:00" quando o programa não é de hoje.
function rotuloDiaEpg(p as Object) as String
    if p = invalid or p.iniTs = invalid or p.iniTs = 0 then return ""
    ini = CreateObject("roDateTime")
    ini.FromSeconds(p.iniTs)
    ini.ToLocalTime()
    hoje = CreateObject("roDateTime")
    hoje.ToLocalTime()
    d1 = ini.AsSeconds() - (ini.GetHours() * 3600 + ini.GetMinutes() * 60 + ini.GetSeconds())
    d2 = hoje.AsSeconds() - (hoje.GetHours() * 3600 + hoje.GetMinutes() * 60 + hoje.GetSeconds())
    dias = Int((d1 - d2) / 86400 + 0.5)
    if dias = 0 then return ""
    en = idiomaEn()
    if dias = 1 then
        if en then return "Tomorrow "
        return "Amanhã "
    end if
    if dias = -1 then
        if en then return "Yesterday "
        return "Ontem "
    end if
    nomesPt = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]
    nomesEn = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    dow = ini.GetWeekday()
    idx = 0
    dd = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    for i = 0 to 6
        if dd[i] = dow then idx = i
    end for
    if en then return nomesEn[idx] + " "
    return nomesPt[idx] + " "
end function
