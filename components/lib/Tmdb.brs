' VLTV Play - Roku | TMDB: título, sinopse, logo, fundo, episódios e guia (EPG) no idioma do app (só em Tarefas).
' Tudo o que o TMDB devolve fica guardado na TV (arquivos pequenos) e não é pesquisado de novo.

function tmdbChave() as String
    k = sv(cfg().tmdbKey)
    if Len(k) > 10 and Left(k, 2) <> "__" then return k
    return ""
end function

function tmdbAtivo() as Boolean
    return tmdbChave() <> ""
end function

function tmdbLingua() as String
    if idiomaEn() then return "en-US"
    return "pt-BR"
end function

function tmdbImagem(caminho as String, tamanho as String) as String
    if caminho = "" then return ""
    base = sv(cfg().imagens)
    if base = "" then base = "https://image.tmdb.org"
    if Left(caminho, 1) <> "/" then caminho = "/" + caminho
    return base + "/t/p/" + tamanho + caminho
end function

' Cache em arquivos pequenos (um por chave).
function tmdbArq(chave as String) as String
    ba = CreateObject("roByteArray")
    ba.FromAsciiString(chave)
    d = CreateObject("roEVPDigest")
    d.Setup("sha1")
    return caminhoCache("t_" + Left(d.Process(ba), 20) + ".json")
end function

function tmdbLer(chave as String, validadeSeg as Integer) as Dynamic
    v = lerJsonArq(tmdbArq(chave))
    if v = invalid or not isAA(v) then return invalid
    if nowSec() - iv(v.t) > validadeSeg then return invalid
    return v
end function

sub tmdbGravar(chave as String, v as Object)
    v.t = nowSec()
    gravarJsonArq(tmdbArq(chave), v)
end sub

function tmdbPegar(url as String) as Object
    return httpJson(url, 6000)
end function

function tmdbNormLetras(t as String) as String
    return CreateObject("roRegex", " ", "").ReplaceAll(norm(t), "")
end function

function tmdbAno(r as Object) as Integer
    d = sv(r.release_date)
    if d = "" then d = sv(r.first_air_date)
    return iv(Left(d, 4))
end function

' Pontos: nome igual (100), começa igual (45), ano igual (+60), vizinho (+30), diferente (-40). Vale a partir de 90.
function tmdbPontuar(r as Object, query as String, ano as String) as Integer
    q = tmdbNormLetras(query)
    s = 0
    nomes = [tmdbNormLetras(sv(r.title)), tmdbNormLetras(sv(r.name)), tmdbNormLetras(sv(r.original_title)), tmdbNormLetras(sv(r.original_name))]
    igual = false
    for each n in nomes
        if n <> "" and n = q then igual = true
    end for
    if igual then
        s = 100
    else
        for each n in nomes
            if Len(q) >= 4 and Len(n) >= 4 and (Left(n, Len(q)) = q or Left(q, Len(n)) = n) then
                if s < 45 then s = 45
            end if
        end for
    end if
    if ano <> "" then
        a = tmdbAno(r)
        if a > 0 then
            dif = Abs(a - iv(ano))
            if dif = 0 then
                s = s + 60
            else if dif = 1 then
                s = s + 30
            else
                s = s - 40
            end if
        end if
    end if
    return s
end function

function tmdbEscolher(resultados as Object, query as String, ano as String) as Dynamic
    melhor = invalid
    pontos = -1000
    n = 0
    for each r in resultados
        n = n + 1
        if n > 10 then exit for
        if isAA(r) then
            p = tmdbPontuar(r, query, ano)
            if p > pontos then
                pontos = p
                melhor = r
            end if
        end if
    end for
    if pontos >= 90 then return melhor
    return invalid
end function

' { ok: false } se a rede falhou; { ok: true, achado: AA|invalid }.
function tmdbProcurar(tipoTmdb as String, query as String, ano as String) as Object
    base = "https://api.themoviedb.org/3/search/" + tipoTmdb + "?api_key=" + tmdbChave() + "&query=" + urlEnc(query) + "&language=pt-BR&region=BR"
    if ano <> "" then
        campo = "&year="
        if tipoTmdb = "tv" then campo = "&first_air_date_year="
        r = tmdbPegar(base + campo + ano)
        if not r.ok then return { ok: false }
        if isAA(r.json) and isLista(r.json.results) then
            a = tmdbEscolher(r.json.results, query, ano)
            if a <> invalid then return { ok: true, achado: a }
        end if
    end if
    r = tmdbPegar(base)
    if not r.ok then return { ok: false }
    if isAA(r.json) and isLista(r.json.results) then return { ok: true, achado: tmdbEscolher(r.json.results, query, ano) }
    return { ok: true, achado: invalid }
end function

function tmdbEscolherLogo(logos as Object) as String
    en = idiomaEn()
    alvo = "pt"
    regiao = "BR"
    if en then
        alvo = "en"
        regiao = "US"
    end if
    for each l in logos
        if LCase(sv(l.iso_639_1)) = alvo and UCase(sv(l.iso_3166_1)) = regiao and sv(l.file_path) <> "" then return sv(l.file_path)
    end for
    for each l in logos
        if LCase(sv(l.iso_639_1)) = alvo and sv(l.file_path) <> "" then return sv(l.file_path)
    end for
    for each l in logos
        if l.iso_639_1 = invalid and sv(l.file_path) <> "" then return sv(l.file_path)
    end for
    return ""
end function

' Título, sinopse, logo e fundo de um filme/série do painel. tipo: "filmes" | "series".
' Resolve { titulo, sinopse, tid, logo, fundo } ou invalid (TMDB não achou ou sem rede).
function tmdbDetalhe(tipo as String, id as String, nome as String) as Dynamic
    if not tmdbAtivo() then return invalid
    lingua = tmdbLingua()
    chave = "d|" + lingua + "|" + tipo + "|" + id
    c = tmdbLer(chave, 2592000)
    if c <> invalid then
        if c.vazio = true then return invalid
        return c
    end if
    c = tmdbLer(chave, 604800)
    if c <> invalid and c.vazio = true then return invalid

    tipoTmdb = "movie"
    if tipo = "series" then tipoTmdb = "tv"
    b = analisarTitulo(nome)
    p = tmdbProcurar(tipoTmdb, b.titulo, b.ano)
    if not p.ok then return invalid
    if p.achado = invalid then
        tmdbGravar(chave, { vazio: true })
        return invalid
    end if
    tid = p.achado.id
    tids = sv(tid)
    base = "https://api.themoviedb.org/3/" + tipoTmdb + "/" + tids + "?api_key=" + tmdbChave()
    d = tmdbPegar(base + "&language=" + lingua)
    if not d.ok or not isAA(d.json) then return invalid
    titulo = sv(d.json.title)
    if titulo = "" then titulo = sv(d.json.name)
    sinopse = sv(d.json.overview)
    logo = ""
    imgLang = "pt-BR,pt,null"
    if idiomaEn() then imgLang = "en,null"
    im = tmdbPegar("https://api.themoviedb.org/3/" + tipoTmdb + "/" + tids + "/images?api_key=" + tmdbChave() + "&include_image_language=" + imgLang)
    if im.ok and isAA(im.json) and isLista(im.json.logos) then
        lp = tmdbEscolherLogo(im.json.logos)
        if lp <> "" then logo = tmdbImagem(lp, "w500")
    end if
    fundo = ""
    bp = sv(p.achado.backdrop_path)
    if bp <> "" then fundo = tmdbImagem(bp, "w1280")
    r = { titulo: titulo, sinopse: sinopse, tid: iv(tid), logo: logo, fundo: fundo }
    tmdbGravar(chave, r)
    return r
end function

' Episódios de uma temporada: { "1": { titulo, imagem }, ... } ou invalid.
function tmdbTemporada(serieId as String, nome as String, numero as String) as Dynamic
    if not tmdbAtivo() then return invalid
    lingua = tmdbLingua()
    chave = "s|" + lingua + "|" + serieId + "|" + numero
    c = tmdbLer(chave, 2592000)
    if c <> invalid and isAA(c.e) then return c.e
    det = tmdbDetalhe("series", serieId, nome)
    if det = invalid or iv(det.tid) = 0 then return invalid
    r = tmdbPegar("https://api.themoviedb.org/3/tv/" + sv(det.tid) + "/season/" + numero + "?api_key=" + tmdbChave() + "&language=" + lingua)
    if not r.ok or not isAA(r.json) then return invalid
    e = {}
    if isLista(r.json.episodes) then
        for each x in r.json.episodes
            if x.episode_number <> invalid then
                e[sv(x.episode_number)] = { titulo: sv(x.name), imagem: tmdbImagem(sv(x.still_path), "w300") }
            end if
        end for
    end if
    tmdbGravar(chave, { e: e })
    return e
end function

' Guia: programa que é filme/série do TMDB ganha título e sinopse em inglês. Só em inglês.
function tmdbEpg(titulo as String) as Dynamic
    nome = titulo.Trim()
    if not tmdbAtivo() or Len(nome) < 2 or not idiomaEn() then return invalid
    chave = "e|en|" + norm(nome)
    c = tmdbLer(chave, 2592000)
    if c <> invalid then
        if c.vazio = true then return invalid
        return c
    end if
    c = tmdbLer(chave, 604800)
    if c <> invalid and c.vazio = true then return invalid
    b = analisarTitulo(nome)
    r = tmdbPegar("https://api.themoviedb.org/3/search/multi?api_key=" + tmdbChave() + "&query=" + urlEnc(b.titulo) + "&language=pt-BR&region=BR")
    if not r.ok then return invalid
    lista = []
    if isAA(r.json) and isLista(r.json.results) then
        for each x in r.json.results
            tp = sv(x.media_type)
            if tp = "movie" or tp = "tv" then lista.Push(x)
        end for
    end if
    achado = tmdbEscolher(lista, b.titulo, b.ano)
    if achado = invalid then
        tmdbGravar(chave, { vazio: true })
        return invalid
    end if
    d = tmdbPegar("https://api.themoviedb.org/3/" + sv(achado.media_type) + "/" + sv(achado.id) + "?api_key=" + tmdbChave() + "&language=en-US")
    if not d.ok or not isAA(d.json) then return invalid
    t = sv(d.json.title)
    if t = "" then t = sv(d.json.name)
    if t = "" then
        tmdbGravar(chave, { vazio: true })
        return invalid
    end if
    res = { titulo: t, sinopse: sv(d.json.overview) }
    tmdbGravar(chave, res)
    return res
end function

' Destaque da semana: igual ao tmdbDetalhe, mas aceita o ID do TMDB (vindo do painel) e devolve também pôster e nota.
' Resolve { titulo, sinopse, logo, fundo, capa, nota, tid } ou invalid.
function tmdbDestaque(tipo as String, tmdbId as String, nome as String) as Dynamic
    if not tmdbAtivo() then return invalid
    lingua = tmdbLingua()
    chave = "ds|" + lingua + "|" + tipo + "|" + tmdbId + "|" + norm(nome)
    c = tmdbLer(chave, 43200)
    if c <> invalid then
        if c.vazio = true then return invalid
        return c
    end if
    tipoTmdb = "movie"
    if tipo = "series" then tipoTmdb = "tv"
    tids = tmdbId
    bp = ""
    if tids = "" then
        b = analisarTitulo(nome)
        p = tmdbProcurar(tipoTmdb, b.titulo, b.ano)
        if not p.ok then return invalid
        if p.achado = invalid then
            tmdbGravar(chave, { vazio: true })
            return invalid
        end if
        tids = sv(p.achado.id)
        bp = sv(p.achado.backdrop_path)
    end if
    d = tmdbPegar("https://api.themoviedb.org/3/" + tipoTmdb + "/" + tids + "?api_key=" + tmdbChave() + "&language=" + lingua)
    if not d.ok or not isAA(d.json) then return invalid
    titulo = sv(d.json.title)
    if titulo = "" then titulo = sv(d.json.name)
    if bp = "" then bp = sv(d.json.backdrop_path)
    fundo = ""
    if bp <> "" then fundo = tmdbImagem(bp, "w1280")
    capa = ""
    pp = sv(d.json.poster_path)
    if pp <> "" then capa = tmdbImagem(pp, "w500")
    logo = ""
    imgLang = "pt-BR,pt,null"
    if idiomaEn() then imgLang = "en,null"
    im = tmdbPegar("https://api.themoviedb.org/3/" + tipoTmdb + "/" + tids + "/images?api_key=" + tmdbChave() + "&include_image_language=" + imgLang)
    if im.ok and isAA(im.json) and isLista(im.json.logos) then
        lp = tmdbEscolherLogo(im.json.logos)
        if lp <> "" then logo = tmdbImagem(lp, "w500")
    end if
    nota = ""
    vn = nv(d.json.vote_average)
    if vn > 0 then nota = Str(Int(vn * 10 + 0.5) / 10).Trim()
    r = { titulo: titulo, sinopse: sv(d.json.overview), logo: logo, fundo: fundo, capa: capa, nota: nota, tid: iv(tids) }
    tmdbGravar(chave, r)
    return r
end function
