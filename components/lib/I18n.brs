' VLTV Play - Roku | Idioma: português do Brasil (padrão) e inglês.
' O app é escrito em português por dentro. Em inglês, cada texto passa por tx() e vira a versão em inglês.
' Categorias e gêneros (que vêm do provedor) são traduzidos palavra por palavra. Títulos e sinopses em
' inglês vêm do TMDB.

sub carregarI18n()
    if m.i18n <> invalid then return
    m.i18n = ParseJson(ReadAsciiFile("pkg:/i18n_en.json"))
    if m.i18n = invalid then m.i18n = { exato: {}, palavras: {}, frases: [] }
    m.i18nMem = {}
end sub

function nomeMes(n as Integer) as String
    meses = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    if n >= 1 and n <= 12 then return meses[n - 1]
    return ""
end function

function dataEn(dd as String, mm as String, aaaa as String) as String
    n = Val(mm)
    if n < 1 or n > 12 then return dd + "/" + mm + "/" + aaaa
    return nomeMes(n) + " " + Str(Val(dd)).Trim() + ", " + aaaa
end function

function diasEn(n as String) as String
    if Val(n) = 1 then return n + " day"
    return n + " days"
end function

function quandoEn(q as String) as String
    if q = "hoje" then return "today"
    if q = "amanhã" then return "tomorrow"
    r = CreateObject("roRegex", "^em (\d+) dias$", "").Match(q)
    if r.Count() > 1 then return "in " + diasEn(r[1])
    return q
end function

' Frases com números ou pedaços variáveis.
function trRegras(s as String) as String
    r = CreateObject("roRegex", "^(\d{2})/(\d{2})/(\d{4}) \((\d+) (?:dia|dias)\)$", "").Match(s)
    if r.Count() > 4 then return dataEn(r[1], r[2], r[3]) + " (" + diasEn(r[4]) + ")"
    r = CreateObject("roRegex", "^(\d{2})/(\d{2})/(\d{4})$", "").Match(s)
    if r.Count() > 3 then return dataEn(r[1], r[2], r[3])
    r = CreateObject("roRegex", "^Ativa até (\d{2})/(\d{2})/(\d{4})$", "").Match(s)
    if r.Count() > 3 then return "Active until " + dataEn(r[1], r[2], r[3])
    r = CreateObject("roRegex", "^Teste grátis: (\d+) (?:dia|dias) \(até (\d{2})/(\d{2})/(\d{4})\)$", "").Match(s)
    if r.Count() > 4 then return "Free trial: " + diasEn(r[1]) + " (until " + dataEn(r[2], r[3], r[4]) + ")"
    r = CreateObject("roRegex", "^Seu teste grátis do aplicativo termina (hoje|amanhã|em \d+ dias)$", "").Match(s)
    if r.Count() > 1 then return "Your app free trial ends " + quandoEn(r[1])
    r = CreateObject("roRegex", "^A licença do aplicativo vence (hoje|amanhã|em \d+ dias)$", "").Match(s)
    if r.Count() > 1 then return "The app license expires " + quandoEn(r[1])
    r = CreateObject("roRegex", "^O plano de canais, filmes e séries vence (hoje|amanhã|em \d+ dias)$", "").Match(s)
    if r.Count() > 1 then return "The channels, movies and series plan expires " + quandoEn(r[1])
    r = CreateObject("roRegex", "^Restam (.+)$", "").Match(s)
    if r.Count() > 1 then return r[1] + " left"
    r = CreateObject("roRegex", "^Episódio (\d+)$", "").Match(s)
    if r.Count() > 1 then return "Episode " + r[1]
    r = CreateObject("roRegex", "^(\d+)\. Episódio (\d+)$", "").Match(s)
    if r.Count() > 2 then return r[1] + ". Episode " + r[2]
    r = CreateObject("roRegex", "^Temporada (\d+)$", "").Match(s)
    if r.Count() > 1 then return "Season " + r[1]
    r = CreateObject("roRegex", "^(\d+) (temporada|temporadas)$", "").Match(s)
    if r.Count() > 1 then
        if r[1] = "1" then return r[1] + " season"
        return r[1] + " seasons"
    end if
    r = CreateObject("roRegex", "^Último episódio da temporada — a seguir: Temporada (\d+)$", "").Match(s)
    if r.Count() > 1 then return "Last episode of the season — up next: Season " + r[1]
    r = CreateObject("roRegex", "^Faltam (\d+) episódios para a próxima temporada$", "").Match(s)
    if r.Count() > 1 then return r[1] + " episodes left until the next season"
    r = CreateObject("roRegex", "^Próximo episódio em (.+)$", "").Match(s)
    if r.Count() > 1 then return "Next episode in " + r[1]
    r = CreateObject("roRegex", "^Agora( \(.*)$", "").Match(s)
    if r.Count() > 1 then return "Now" + r[1]
    r = CreateObject("roRegex", "^código de parceiro: (.*)$", "").Match(s)
    if r.Count() > 1 then return "partner code: " + r[1]
    r = CreateObject("roRegex", "^Digite o nome de (um filme|uma série) para pesquisar\.$", "").Match(s)
    if r.Count() > 1 then
        if r[1] = "um filme" then return "Type the name of a movie to search."
        return "Type the name of a series to search."
    end if
    r = CreateObject("roRegex", "^Nenhum (filme|série) encontrado( até agora)? para ""(.*)""\.$", "").Match(s)
    if r.Count() > 3 then
        tipo = "series"
        if r[1] = "filme" then tipo = "movies"
        extra = ""
        if r[2] <> "" then extra = " so far"
        return "No " + tipo + " found" + extra + " for """ + r[3] + """."
    end if
    r = CreateObject("roRegex", "^O servidor recusou o acesso \(erro (\d+)\)\. Confira se o plano está ativo\.$", "").Match(s)
    if r.Count() > 1 then return "The server refused access (error " + r[1] + "). Check that the plan is active."
    r = CreateObject("roRegex", "^O servidor está com problema \(erro (\d+)\)\. Tente de novo em instantes\.$", "").Match(s)
    if r.Count() > 1 then return "The server has a problem (error " + r[1] + "). Try again in a moment."
    r = CreateObject("roRegex", "^O servidor respondeu com erro (\d+)\.$", "").Match(s)
    if r.Count() > 1 then return "The server responded with error " + r[1] + "."
    return s
end function

' Traduz uma frase do app. Em português devolve a própria frase.
function tx(texto as String) as String
    if not idiomaEn() then return texto
    if texto = "" or Len(texto) > 600 then return texto
    carregarI18n()
    if m.i18nMem[texto] <> invalid then return m.i18nMem[texto]
    miolo = texto.Trim()
    r = texto
    if miolo <> "" then
        ex = m.i18n.exato[miolo]
        if ex <> invalid then
            r = ex
        else
            ' "Gênero:" -> "Genre:"
            if Len(miolo) > 2 and Right(miolo, 1) = ":" then
                ex = m.i18n.exato[Left(miolo, Len(miolo) - 1)]
            end if
            if ex <> invalid then
                r = ex + ":"
            else if contem(miolo, "  •  ") then
                partes = []
                for each p in splitTexto(miolo, "  •  ")
                    partes.Push(tx(p))
                end for
                r = partes.Join("  •  ")
            else
                r = trRegras(miolo)
            end if
        end if
    end if
    m.i18nMem[texto] = r
    return r
end function

function splitTexto(s as String, sep as String) as Object
    saida = []
    resto = s
    while true
        p = Instr(1, resto, sep)
        if p = 0 then exit while
        saida.Push(Left(resto, p - 1))
        resto = Mid(resto, p + Len(sep))
    end while
    saida.Push(resto)
    return saida
end function

' Mantém a "cara" da palavra original (MAIÚSCULAS, Primeira Maiúscula).
function estiloPalavra(orig as String, en as String) as String
    if Len(orig) > 1 and orig = UCase(orig) and orig <> LCase(orig) then return UCase(en)
    if Len(orig) > 0 and Left(orig, 1) <> LCase(Left(orig, 1)) then return UCase(Left(en, 1)) + Mid(en, 2)
    return en
end function

' Categorias e gêneros do provedor: só as palavras conhecidas mudam.
function trCat(texto as String) as String
    if not idiomaEn() then return texto
    if texto = "" or Len(texto) > 200 then return texto
    carregarI18n()
    if m.i18nMem["c|" + texto] <> invalid then return m.i18nMem["c|" + texto]
    ex = m.i18n.exato[texto.Trim()]
    if ex <> invalid then
        m.i18nMem["c|" + texto] = ex
        return ex
    end if
    saida = ""
    reP = CreateObject("roRegex", "[A-Za-zÀ-ÿ0-9+]+", "")
    resto = texto
    ' percorre palavra por palavra, mantendo a pontuação
    n = norm(texto)
    pals = CreateObject("roRegex", "[^A-Za-zÀ-ÿ0-9+]+", "").Split(texto)
    seps = []
    ' separadores: reconstrói com o que sobra entre as palavras
    resultado = ""
    posicao = 1
    for each pal in pals
        if pal <> "" then
            ini = Instr(posicao, texto, pal)
            if ini > posicao then resultado = resultado + Mid(texto, posicao, ini - posicao)
            chave = LCase(semAcento(pal))
            en = m.i18n.palavras[chave]
            if en <> invalid then
                resultado = resultado + estiloPalavra(pal, en)
            else
                resultado = resultado + pal
            end if
            posicao = ini + Len(pal)
        end if
    end for
    resultado = resultado + Mid(texto, posicao)
    ' frases de duas palavras
    for each f in m.i18n.frases
        if LCase(semAcento(resultado)) = f[0] then resultado = f[1]
    end for
    m.i18nMem["c|" + texto] = resultado
    return resultado
end function
