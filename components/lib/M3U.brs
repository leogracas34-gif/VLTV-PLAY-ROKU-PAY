' VLTV Play - Roku | Lista M3U: baixa, separa em TV ao vivo, filmes e séries e guarda em arquivos (só em Tarefas).
' A Roku tem pouca memória: a lista é lida uma vez e cada categoria vira um arquivo pequeno.

function m3uMaxBytes() as Integer
    return 8000000
end function

function m3uArq(nome as String) as String
    return caminhoCache("m3u_" + nome + ".json")
end function

function m3uPronto(url as String) as Boolean
    return regGet("m3u_fonte") = url and arqExiste(m3uArq("idx")) and iv(regGet("m3u_em")) > nowSec() - 21600
end function

' Resolve "ok" | "rede" | "tamanho" | "vazia"
function m3uCarregar(url as String) as String
    if m3uPronto(url) then return "ok"
    bruto = caminhoCache("m3u_raw.txt")
    arqApagar(bruto)
    r = httpArquivo(url, bruto, 120000)
    if not r.ok then return "rede"
    fs = CreateObject("roFileSystem")
    st = fs.Stat(bruto)
    if st = invalid or st.size > m3uMaxBytes() then
        arqApagar(bruto)
        return "tamanho"
    end if
    texto = ReadAsciiFile(bruto)
    arqApagar(bruto)
    if texto = "" then return "vazia"
    total = m3uParsear(texto)
    texto = ""
    if total = 0 then return "vazia"
    regSet("m3u_fonte", url)
    regSet("m3u_em", Str(nowSec()).Trim())
    return "ok"
end function

function m3uAtributos(linha as String) as Object
    attrs = {}
    if m.reM3uAttr = invalid then m.reM3uAttr = CreateObject("roRegex", "([A-Za-z0-9_\-]+)=""([^""]*)""", "")
    for each g in m.reM3uAttr.MatchAll(linha)
        attrs[LCase(g[1])] = g[2]
    end for
    return attrs
end function

function m3uClassificar(nome as String, url as String) as String
    if m.reM3uArq = invalid then m.reM3uArq = CreateObject("roRegex", "\.(mp4|mkv|avi|mov|wmv|flv|mpg|mpeg)(\?|$)", "i")
    if m.reM3uEp = invalid then m.reM3uEp = CreateObject("roRegex", "^(.*?)[\s._-]*S(\d{1,3})\s*[._-]?\s*E(\d{1,4})", "i")
    ehArq = m.reM3uArq.IsMatch(url)
    if Instr(1, LCase(url), "/series/") > 0 or (ehArq and m.reM3uEp.IsMatch(nome)) then return "series"
    if Instr(1, LCase(url), "/movie/") > 0 or ehArq then return "filmes"
    return "ao_vivo"
end function

function m3uNovoGrupo() as Object
    return { cats: [], porCat: {}, indice: {} }
end function

function m3uCategoria(g as Object, nome as String) as String
    if g.indice[nome] = invalid then
        id = "g" + Str(g.cats.Count()).Trim()
        g.indice[nome] = id
        g.cats.Push({ category_id: id, category_name: nome })
        g.porCat[id] = []
    end if
    return g.indice[nome]
end function

' Lê o texto linha por linha, separa e grava os arquivos. Devolve o total de itens.
function m3uParsear(texto as String) as Integer
    grupos = { ao_vivo: m3uNovoGrupo(), filmes: m3uNovoGrupo(), series: m3uNovoGrupo() }
    mapaSeries = {}
    seriesEps = {}
    total = 0
    proximoId = 1
    atual = invalid
    posicao = 1
    tam = Len(texto)
    while posicao <= tam
        fim = Instr(posicao, texto, Chr(10))
        if fim = 0 then fim = tam + 1
        linha = Mid(texto, posicao, fim - posicao).Trim()
        posicao = fim + 1
        if linha <> "" then
            if startsWith(linha, "#EXTINF") then
                attrs = m3uAtributos(linha)
                ult = 0
                for i = Len(linha) to 1 step -1
                    if Mid(linha, i, 1) = "," then
                        ult = i
                        exit for
                    end if
                next
                nome = ""
                if ult > 0 then nome = Mid(linha, ult + 1).Trim()
                if nome = "" then nome = sv(attrs["tvg-name"])
                if nome = "" then nome = "Sem nome"
                grupo = sv(attrs["group-title"])
                if grupo = "" then grupo = "Sem grupo"
                atual = { name: nome, logo: sv(attrs["tvg-logo"]), grupo: grupo }
            else if Left(linha, 1) <> "#" and atual <> invalid then
                atual.url = linha
                total = total + 1
                m3uAdicionar(grupos, mapaSeries, seriesEps, atual, proximoId)
                proximoId = proximoId + 1
                atual = invalid
            end if
        end if
    end while

    indice = {}
    for each tipo in ["ao_vivo", "filmes", "series"]
        g = grupos[tipo]
        indice[tipo] = g.cats
        for each c in g.cats
            gravarJsonArq(m3uArq(tipo + "_" + c.category_id), g.porCat[c.category_id])
        end for
    end for
    for each sid in seriesEps
        gravarJsonArq(m3uArq("s_" + sid), seriesEps[sid])
    end for
    gravarJsonArq(m3uArq("idx"), indice)
    return total
end function

sub m3uAdicionar(grupos as Object, mapaSeries as Object, seriesEps as Object, item as Object, id as Integer)
    tipo = m3uClassificar(item.name, item.url)
    ids = Str(id).Trim()
    if tipo = "ao_vivo" then
        cat = m3uCategoria(grupos.ao_vivo, item.grupo)
        grupos.ao_vivo.porCat[cat].Push({ stream_id: id, name: item.name, stream_icon: item.logo, url: item.url })
        return
    end if
    if tipo = "filmes" then
        cat = m3uCategoria(grupos.filmes, item.grupo)
        grupos.filmes.porCat[cat].Push({ stream_id: id, name: item.name, stream_icon: item.logo, container_extension: "", url: item.url })
        return
    end if
    ' Série: agrupa os episódios pelo nome da série.
    r = m.reM3uEp.Match(item.name)
    nomeSerie = item.name
    temporada = "1"
    numero = 1
    if r.Count() > 3 then
        if r[1].Trim() <> "" then nomeSerie = r[1].Trim()
        temporada = Str(Val(r[2])).Trim()
        numero = Val(r[3])
    end if
    chave = item.grupo + "||" + nomeSerie
    sid = mapaSeries[chave]
    if sid = invalid then
        cat = m3uCategoria(grupos.series, item.grupo)
        sid = "s" + ids
        mapaSeries[chave] = sid
        grupos.series.porCat[cat].Push({ series_id: sid, name: nomeSerie, cover: item.logo, category_id: cat })
        seriesEps[sid] = {}
    end if
    if seriesEps[sid][temporada] = invalid then seriesEps[sid][temporada] = []
    seriesEps[sid][temporada].Push({ id: id, title: item.name, episode_num: numero, container_extension: "", season: temporada, url: item.url })
end sub

function m3uCats(tipo as String) as Object
    idx = lerJsonArq(m3uArq("idx"))
    if idx = invalid or idx[tipo] = invalid then return []
    return idx[tipo]
end function

function m3uItens(tipo as String, cat as String) as Object
    v = lerJsonArq(m3uArq(tipo + "_" + cat))
    if v = invalid or not isLista(v) then return []
    return v
end function

' Série no formato da tela de episódios: { info, temporadas: [{ numero, episodios }] }
function m3uInfoSerie(id as String) as Object
    v = lerJsonArq(m3uArq("s_" + id))
    if v = invalid or not isAA(v) then return { info: {}, temporadas: [] }
    chaves = []
    for each k in v
        chaves.Push(Val(k))
    end for
    chaves.Sort()
    temporadas = []
    for each n in chaves
        k = Str(n).Trim()
        eps = v[k]
        if eps <> invalid
            eps.SortBy("episode_num")
            temporadas.Push({ numero: k, episodios: eps })
        end if
    end for
    return { info: {}, temporadas: temporadas }
end function
