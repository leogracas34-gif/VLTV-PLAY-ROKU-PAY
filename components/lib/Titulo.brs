' VLTV Play - Roku | "Vassoura" de nomes: tira do nome do painel o que não faz parte do título
' (ano, HD, legendado, dublado, S01E01, [colchetes], (parênteses)...). Mesma ideia do app da LG.

sub prepararTitulo()
    if m.reTitTags <> invalid then return
    L = "A-Za-z0-9"
    m.reTitTags = CreateObject("roRegex", "(^|[^" + L + "])(DUAL AUDIO|DUAL\-AUDIO|LANÇAMENTO|LANCAMENTO|LEGENDADO|LEGENDADA|SUBTITLED|EXCLUSIVO|TEMPORADA|SCREENER|NACIONAL|COMPLETE|FULL HD|FULL\-HD|BLU\-RAY|DUBLADO|DUBLADA|FULLHD|BLURAY|REPACK|WEB\-DL|WEBRIP|DVDRIP|DVDSCR|LATINO|DUBBED|CINEMA|SEASON|HDR10|1080P|2160P|H\.264|H\.265|BDRIP|REMUX|UNCUT|WEBDL|BRRIP|HDCAM|HDRIP|MULTI|PT\-BR|720P|480P|H264|H265|X264|X265|HEVC|HDTV|DUAL|SUBS|PTBR|FHD|UHD|HDR|AVC|AVI|MKV|MP4|5\.1|2\.0|AAC|AC3|LEG|DUB|HD|4K|8K|DV)(?=$|[^" + L + "])", "i")
    m.reTitFracas = CreateObject("roRegex", "([^" + L + "])(WEB|TS|TC|DV|SUB|SUBS|AUDIO|MULTI|ESP|ITA|SP|BR|AVC|CAM|COMPLETE|COMPLETO|EXTENDED|UNCUT|PROPER|SD|R5)(?=$|[^" + L + "])", "i")
    m.reTitRes = CreateObject("roRegex", "(^|[^" + L + "])(\d{3,4}p|hd\d{3,4}|\d{3,4}x\d{3,4})(?=$|[^" + L + "])", "i")
    m.reTitGrupo = CreateObject("roRegex", "[\(\[\{]([^\)\]\}]*)[\)\]\}]", "")
    m.reTitAnoDentro = CreateObject("roRegex", "\b((19|20)\d{2})\b", "")
    m.reTitTemp = CreateObject("roRegex", "^(S\d{1,2}(E\d{1,3})?|E\d{1,3}|EP\d{1,3})$", "i")
    m.reTitAno = CreateObject("roRegex", "^(19|20)\d{2}$", "")
    m.reTitPrefixo = CreateObject("roRegex", "^\s*(BR|SP|PT|PTBR|LEG|DUB)\s*(?::|-|–)\s+", "i")
    m.reTitSep = CreateObject("roRegex", "[|_]", "")
    m.reTitEsp = CreateObject("roRegex", "\s+", "")
end sub

function ehAnoTit(t as String) as Boolean
    if not m.reTitAno.IsMatch(t) then return false
    n = Val(t)
    return n >= 1900 and n <= anoAtual() + 2
end function

' Letra ou número (qualquer letra com acento conta como letra).
function ehLetraTit(c as String) as Boolean
    a = Asc(c)
    if a >= 48 and a <= 57 then return true
    if a >= 65 and a <= 90 then return true
    if a >= 97 and a <= 122 then return true
    return a >= 192
end function

function semPontasTit(t as String) as String
    ini = 1
    fim = Len(t)
    while ini <= fim and not ehLetraTit(Mid(t, ini, 1))
        ini = ini + 1
    end while
    while fim >= ini and not ehLetraTit(Mid(t, fim, 1))
        fim = fim - 1
    end while
    if fim < ini then return ""
    return Mid(t, ini, fim - ini + 1)
end function

' Tira espaço, traços, dois-pontos, ponto e vírgula das pontas.
function aparaPontuacao(t as String) as String
    sobra = " -–—:.,"
    ini = 1
    fim = Len(t)
    while ini <= fim and Instr(1, sobra, Mid(t, ini, 1)) > 0
        ini = ini + 1
    end while
    while fim >= ini and Instr(1, sobra, Mid(t, fim, 1)) > 0
        fim = fim - 1
    end while
    if fim < ini then return ""
    return Mid(t, ini, fim - ini + 1)
end function

function contarChar(s as String, c as String) as Integer
    n = 0
    for i = 1 to Len(s)
        if Mid(s, i, 1) = c then n = n + 1
    end for
    return n
end function

' Devolve { titulo, ano }.
function analisarTitulo(nomeOriginal as String) as Object
    prepararTitulo()
    original = m.reTitEsp.ReplaceAll(nomeOriginal, " ").Trim()
    ano = ""

    ' Ano entre parênteses/colchetes vira "ano"; o resto desses grupos é descartado.
    texto = original
    grupos = m.reTitGrupo.MatchAll(texto)
    for each g in grupos
        dentro = g[1]
        a = m.reTitAnoDentro.Match(dentro)
        if a.Count() > 1 and ano = "" and ehAnoTit(a[1]) then ano = a[1]
    end for
    texto = m.reTitGrupo.ReplaceAll(texto, " ")
    texto = m.reTitSep.ReplaceAll(texto, " ")

    ' Nome de arquivo ("Filme.Nome.1080p.Dublado"): os pontos fazem o papel de espaço.
    if not contem(texto, " ") and contarChar(texto, ".") >= 2 then texto = texto.Replace(".", " ")
    if not contem(texto, " ") and contarChar(texto, "-") >= 2 then texto = texto.Replace("-", " ")

    ' Prefixo de idioma do painel: "BR: Duna", "SP - Duna".
    texto = m.reTitPrefixo.Replace(texto, "")

    antes = texto
    for vez = 1 to 3
        texto = m.reTitTags.ReplaceAll(texto, "\1 ")
        texto = m.reTitFracas.ReplaceAll(texto, "\1 ")
        texto = m.reTitRes.ReplaceAll(texto, "\1 ")
    end for
    tirouTag = (texto <> antes)

    palavras = []
    for each p in m.reTitEsp.Split(texto.Trim())
        if p <> "" then palavras.Push(p)
    end for

    mantidas = []
    for each p in palavras
        limpa = semPontasTit(p)
        if not m.reTitTemp.IsMatch(limpa) then mantidas.Push(p)
    end for

    ' "Filme - L" / "Filme | D" (marca de legendado/dublado): sai.
    if mantidas.Count() > 1
        ult = UCase(semPontasTit(mantidas[mantidas.Count() - 1]))
        if ult = "L" or ult = "D"
            anterior = mantidas[mantidas.Count() - 2]
            if semPontasTit(anterior) = "" or tirouTag then mantidas.Pop()
        end if
    end if

    mantidas = aparaSoltos(mantidas)

    ' Ano solto no fim do nome ("Reacher 2022"): sai, mas só se sobrar algum título.
    while mantidas.Count() > 1 and ehAnoTit(semPontasTit(mantidas[mantidas.Count() - 1]))
        a = semPontasTit(mantidas.Pop())
        if ano = "" then ano = a
        mantidas = aparaSoltos(mantidas)
    end while

    titulo = mantidas.Join(" ")
    titulo = aparaPontuacao(titulo)
    if titulo = "" then titulo = original
    return { titulo: titulo, ano: ano }
end function

function aparaSoltos(lista as Object) as Object
    while lista.Count() > 0 and semPontasTit(lista[lista.Count() - 1]) = ""
        lista.Pop()
    end while
    while lista.Count() > 0 and semPontasTit(lista[0]) = ""
        lista.Shift()
    end while
    return lista
end function

function limparTitulo(nome as String) as String
    return analisarTitulo(nome).titulo
end function
