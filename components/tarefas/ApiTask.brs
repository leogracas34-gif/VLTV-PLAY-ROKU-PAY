' VLTV Play - Roku | Tarefa de dados do painel (categorias, títulos, detalhes, guia, destaques, créditos).
'   op "cats"          params { tipo: ao_vivo|filmes|series, modo: cache|rede }
'   op "itens"         params { tipo, cat, modo: cache|rede }
'   op "info_filme"    params { id }
'   op "info_serie"    params { id }
'   op "epg"           params { id, limite }
'   op "banner"        params { modo: cache|rede }
'   op "creditos_buscar"  params { serie }      op "creditos_enviar"  params { serie, seg }
sub init()
    m.top.functionName = "executar"
end sub

sub executar()
    p = m.top.params
    if p = invalid then p = {}
    s = sessaoLer()
    if s = invalid then
        m.top.result = { ok: false, erro: "sem_sessao" }
        return
    end if
    op = m.top.op
    r = { ok: false }
    if op = "cats" then
        r = opLista(s, p, true)
    else if op = "itens" then
        r = opLista(s, p, false)
    else if op = "info_filme" then
        r = opInfoFilme(s, p)
    else if op = "info_serie" then
        r = opInfoSerie(s, p)
    else if op = "epg" then
        r = opEpg(s, p)
    else if op = "banner" then
        r = opBanner(s, p)
    else if op = "aquecer" then
        r = opAquecer(s, p)
    else if op = "creditos_buscar" then
        r = opCreditosBuscar(s, p)
    else if op = "creditos_enviar" then
        r = opCreditosEnviar(s, p)
    end if
    m.top.result = r
end sub

' ── Categorias e títulos (com cópia guardada na TV) ─────────────────
function arqLista(s as Object, nome as String) as String
    return caminhoCache("l_" + hashCurto(chaveLista(s) + "|" + nome) + ".json")
end function

' Só o que as telas usam: a lista fica bem menor na memória e no arquivo.
function enxugar(tipo as String, lista as Object) as Object
    campos = []
    if tipo = "filmes" then
        campos = ["stream_id", "name", "stream_icon", "container_extension", "rating", "added", "category_id", "is_adult", "year", "releaseDate"]
    else if tipo = "series" then
        campos = ["series_id", "name", "cover", "rating", "category_id", "last_modified", "year", "releaseDate"]
    else
        campos = ["stream_id", "name", "stream_icon", "category_id", "epg_channel_id", "is_adult", "url"]
    end if
    saida = []
    for each x in lista
        if isAA(x) then
            o = {}
            for each c in campos
                if x[c] <> invalid then o[c] = x[c]
            end for
            saida.Push(o)
        end if
    end for
    return saida
end function

function opLista(s as Object, p as Object, ehCats as Boolean) as Object
    tipo = sv(p.tipo)
    cat = sv(p.cat)
    ' Lista M3U: já está em arquivos pequenos, não precisa de cópia.
    if s.modo = "m3u" then
        if ehCats then return { ok: true, lista: m3uCats(tipo) }
        return { ok: true, lista: m3uItens(tipo, cat) }
    end if

    nome = tipo + "|cats"
    if not ehCats then nome = tipo + "|itens|" + cat
    arq = arqLista(s, nome)

    if sv(p.modo) = "cache" then
        c = lerJsonArq(arq)
        if c <> invalid and isAA(c) and isLista(c.lista) then
            return { ok: true, lista: c.lista, doCache: true, velho: (nowSec() - iv(c.t) > 600) }
        end if
        return { ok: false, semCache: true }
    end if

    acao = ""
    extra = ""
    if ehCats then
        if tipo = "filmes" then acao = "get_vod_categories"
        if tipo = "series" then acao = "get_series_categories"
        if tipo = "ao_vivo" then acao = "get_live_categories"
    else
        if tipo = "filmes" then acao = "get_vod_streams"
        if tipo = "series" then acao = "get_series"
        if tipo = "ao_vivo" then acao = "get_live_streams"
        extra = "&category_id=" + urlEnc(cat)
    end if
    dados = xtreamPedir(s, acao, extra, 30000)
    if dados = invalid or not isLista(dados) then return { ok: false, erro: "rede" }
    lista = dados
    if not ehCats then lista = enxugar(tipo, dados)
    ' Lista vazia quase sempre é erro do painel: não guarda.
    if lista.Count() > 0 then gravarJsonArq(arq, { lista: lista, t: nowSec() })
    return { ok: true, lista: lista }
end function

' ── Detalhes ──────────────────────────────────────────────────────────
function opInfoFilme(s as Object, p as Object) as Object
    if s.modo = "m3u" then return { ok: true, info: {} }
    d = xtreamPedir(s, "get_vod_info", "&vod_id=" + urlEnc(sv(p.id)), 20000)
    if d = invalid or not isAA(d) then return { ok: false }
    info = {}
    if isAA(d.info) then info = d.info
    dados = {}
    if isAA(d.movie_data) then dados = d.movie_data
    return { ok: true, info: info, dados: dados }
end function

function opInfoSerie(s as Object, p as Object) as Object
    id = sv(p.id)
    if s.modo = "m3u" then
        r = m3uInfoSerie(id)
        return { ok: true, info: r.info, temporadas: r.temporadas }
    end if
    d = xtreamPedir(s, "get_series_info", "&series_id=" + urlEnc(id), 25000)
    if d = invalid or not isAA(d) then return { ok: false }
    info = {}
    if isAA(d.info) then info = d.info
    bruto = d.episodes
    porTemp = {}
    ordem = []
    if isLista(bruto) then
        for each ep in bruto
            n = sv(ep.season)
            if n = "" then n = "1"
            if porTemp[n] = invalid then
                porTemp[n] = []
                ordem.Push(Val(n))
            end if
            porTemp[n].Push(ep)
        end for
    else if isAA(bruto) then
        for each n in bruto
            if isLista(bruto[n]) then
                porTemp[n] = bruto[n]
                ordem.Push(Val(n))
            end if
        end for
    end if
    ordem.Sort()
    temporadas = []
    for each nn in ordem
        k = Str(nn).Trim()
        eps = []
        if porTemp[k] <> invalid then
            for each e in porTemp[k]
                ' só os campos usados: o painel manda muita coisa
                inf = {}
                if isAA(e.info) then inf = e.info
                eps.Push({
                    id: sv(e.id), title: sv(e.title), episode_num: iv(e.episode_num), season: k,
                    container_extension: sv(e.container_extension),
                    capa: urlImagem(inf.movie_image), duracao: sv(inf.duration), duracao_seg: iv(inf.duration_secs),
                    sinopse: sv(inf.plot)
                })
            end for
        end if
        eps.SortBy("episode_num")
        if eps.Count() > 0 then temporadas.Push({ numero: k, episodios: eps })
    end for
    return { ok: true, info: info, temporadas: temporadas }
end function

' ── Guia de programação ─────────────────────────────────────────────
function opEpg(s as Object, p as Object) as Object
    if s.modo = "m3u" then return { ok: true, lista: [] }
    id = sv(p.id)
    limite = iv(p.limite)
    if limite <= 0 then limite = 2
    d = xtreamPedir(s, "get_short_epg", "&stream_id=" + urlEnc(id) + "&limit=" + Str(limite).Trim(), 15000)
    lista = []
    if d <> invalid and isAA(d) and isLista(d.epg_listings) then lista = normalizarEpg(d.epg_listings)
    agora = nowSec()
    util = false
    for each x in lista
        if x.fimTs = 0 or x.fimTs > agora then util = true
    end for
    if util then return { ok: true, lista: lista }
    ' O guia curto veio vazio: tenta a tabela completa do canal.
    d = xtreamPedir(s, "get_simple_data_table", "&stream_id=" + urlEnc(id), 20000)
    if d <> invalid and isAA(d) and isLista(d.epg_listings) then
        todos = normalizarEpg(d.epg_listings)
        saida = []
        for each x in todos
            if (x.fimTs = 0 or x.fimTs > agora) and saida.Count() < limite then saida.Push(x)
        end for
        return { ok: true, lista: saida }
    end if
    return { ok: true, lista: lista }
end function

' ── Destaques da Home (backend da VPS: Top 10) ─────────────────────
function pegarVps(caminho as String) as Dynamic
    base = sv(cfg().vps)
    if base = "" then return invalid
    ' 15 s (antes 4 s): o pacote /catalog/inicial é grande e a Roku demora mais que a TV LG para baixar.
    r = httpJson(base + caminho, 15000)
    print "[banner] "; caminho; " status="; r.status; " bytes="; Len(sv(r.texto))
    if r.ok then return r.json
    return invalid
end function

function slideDe(tipo as String, raw as Object, etiqueta as String, rank as Integer) as Dynamic
    capa = ""
    id = ""
    if tipo = "series" then
        capa = urlImagem(raw.cover)
        id = sv(raw.series_id)
    else
        capa = urlImagem(raw.stream_icon)
        id = sv(raw.stream_id)
    end if
    nome = sv(raw.name)
    if capa = "" or nome = "" then return invalid
    b = analisarTitulo(nome)
    nota = nv(raw.rating)
    notaTxt = ""
    if nota > 0 then notaTxt = Str(Int(nota * 10 + 0.5) / 10).Trim()
    return { tipo: tipo, id: id, nome: b.titulo, nomeBruto: nome, capa: capa, etiqueta: etiqueta, nota: notaTxt, ano: b.ano, rank: rank }
end function

function opBanner(s as Object, p as Object) as Object
    arq = caminhoCache("banner.json")
    if sv(p.modo) = "cache" then
        c = lerJsonArq(arq)
        if c <> invalid and isAA(c) and sv(c.dono) = chaveLista(s) and isLista(c.slides) and c.slides.Count() > 0 then return { ok: true, slides: c.slides, doCache: true }
        return { ok: false, semCache: true }
    end if
    slides = []
    dom = dominioBackend(s)
    if dom <> "" and s.modo <> "m3u" then
        q = "?domain=" + urlEnc(dom)
        home = pegarVps("/home" + q)
        pacote = pegarVps("/catalog/inicial" + q)
        if isAA(home) and isAA(pacote) and isAA(home.top10) then
            filmes = {}
            series = {}
            if isLista(pacote.vod_streams) then
                for each v in pacote.vod_streams
                    filmes[sv(v.stream_id)] = v
                end for
            end if
            if isLista(pacote.series_streams) then
                for each v in pacote.series_streams
                    series[sv(v.series_id)] = v
                end for
            end if
            topF = ordenarRank(home.top10.filmes)
            topS = ordenarRank(home.top10.series)
            n = topF.Count()
            if topS.Count() > n then n = topS.Count()
            i = 0
            while i < n and slides.Count() < 8
                if i < topF.Count() then
                    rf = filmes[sv(topF[i].stream_id)]
                    if rf <> invalid then
                        sl = slideDe("filmes", rf, "TOP 10 FILMES  •  #" + sv(topF[i].rank), iv(topF[i].rank))
                        if sl <> invalid then
                            sl.daVps = true
                            slides.Push(sl)
                        end if
                    end if
                end if
                if i < topS.Count() and slides.Count() < 8 then
                    rs = series[sv(topS[i].series_id)]
                    if rs <> invalid then
                        sl = slideDe("series", rs, "TOP 10 SÉRIES  •  #" + sv(topS[i].rank), iv(topS[i].rank))
                        if sl <> invalid then
                            sl.daVps = true
                            slides.Push(sl)
                        end if
                    end if
                end if
                i = i + 1
            end while
        end if
    end if

    ' Sem a VPS: primeiros títulos com capa das primeiras categorias do próprio painel.
    if slides.Count() = 0 then slides = bannerDoPainel(s)

    if slides.Count() > 0 then gravarJsonArq(arq, { dono: chaveLista(s), slides: slides })
    return { ok: slides.Count() > 0, slides: slides }
end function

function ordenarRank(lista as Dynamic) as Object
    if not isLista(lista) then return []
    saida = []
    for each x in lista
        if isAA(x) then
            if x.rank = invalid then x.rank = 99
            saida.Push(x)
        end if
    end for
    saida.SortBy("rank")
    return saida
end function

function bannerDoPainel(s as Object) as Object
    slides = []
    for each tipo in ["filmes", "series"]
        etiqueta = "FILME EM DESTAQUE"
        if tipo = "series" then etiqueta = "SÉRIE EM DESTAQUE"
        cats = opLista(s, { tipo: tipo, modo: "rede" }, true)
        if cats.ok then
            usadas = 0
            for each c in cats.lista
                if usadas < 3 and not ehCatAdulta(sv(c.category_name)) then
                    usadas = usadas + 1
                    it = opLista(s, { tipo: tipo, cat: sv(c.category_id), modo: "rede" }, false)
                    if it.ok then
                        n = 0
                        for each x in it.lista
                            if n < 3 and not ehNomeAdulto(sv(x.name)) then
                                sl = slideDe(tipo, x, etiqueta, 0)
                                if sl <> invalid then
                                    slides.Push(sl)
                                    n = n + 1
                                end if
                            end if
                        end for
                    end if
                end if
            end for
        end if
    end for
    return slides
end function

' ── Créditos aprendidos (botão "Próximo episódio") ──────────────────
function dominioCreditos(s as Object) as String
    d = dominioBackend(s).Trim()
    if d = "" then return ""
    return semBarraFinal(d) + "/"
end function

function credLocal(serie as String) as Integer
    d = lerJsonArq(caminhoCache("cred.json"))
    if d = invalid or not isAA(d) or d[serie] = invalid then return 0
    return iv(d[serie])
end function

sub credGravar(serie as String, seg as Integer)
    d = lerJsonArq(caminhoCache("cred.json"))
    if d = invalid or not isAA(d) then d = {}
    d[serie] = seg
    gravarJsonArq(caminhoCache("cred.json"), d)
end sub

function opCreditosBuscar(s as Object, p as Object) as Object
    local = credLocal(sv(p.serie))
    base = sv(cfg().vps)
    dom = dominioCreditos(s)
    serie = iv(p.serie)
    if base <> "" and dom <> "" and serie > 0 then
        j = httpJson(base + "/credits?domain=" + urlEnc(dom) + "&series=" + Str(serie).Trim(), 6000)
        if j.ok and isAA(j.json) then
            v = iv(j.json.remaining_sec)
            if v >= 5 and v <= 600 then
                credGravar(sv(p.serie), v)
                return { ok: true, seg: v }
            end if
        end if
    end if
    if local > 0 then return { ok: true, seg: local }
    return { ok: false }
end function

function opCreditosEnviar(s as Object, p as Object) as Object
    seg = iv(p.seg)
    if seg < 5 or seg > 600 then return { ok: false }
    credGravar(sv(p.serie), seg)
    base = sv(cfg().vps)
    chave = sv(cfg().vpsKey)
    dom = dominioCreditos(s)
    serie = iv(p.serie)
    if base = "" or dom = "" or serie <= 0 or Left(chave, 2) = "__" then return { ok: false }
    corpo = FormatJson({ domain: dom, series: serie, remaining_sec: seg })
    r = httpSync(base + "/credits", "POST", corpo, { "Content-Type": "application/json", "x-app-key": chave }, 6000)
    return { ok: r.ok }
end function

' ── Pré-carregamento (igual ao "preparar" da LG) ────────────────────
' Baixa e guarda na TV, sem mostrar nada, o que o usuário provavelmente vai abrir: assim a tela já nasce cheia.
'   params.tipos: ["filmes","series","ao_vivo"] -> categorias + as primeiras listas (3; no ao vivo, 1), sem categoria adulta
'   params.cats:  [{ tipo, cat }]               -> listas específicas (as categorias vizinhas da que está aberta)
function opAquecer(s as Object, p as Object) as Object
    if s.modo = "m3u" then return { ok: true }
    if isLista(p.tipos) then
        for each tipo in p.tipos
            n = 3
            if tipo = "ao_vivo" then n = 1
            cats = aquecerUma(s, sv(tipo), "", true)
            if cats <> invalid then
                usadas = 0
                for each c in cats
                    if usadas >= n then exit for
                    if not ehCatAdulta(sv(c.category_name)) then
                        usadas = usadas + 1
                        aquecerUma(s, sv(tipo), sv(c.category_id), false)
                        sleep(250)
                    end if
                end for
            end if
        end for
    end if
    if isLista(p.cats) then
        for each x in p.cats
            aquecerUma(s, sv(x.tipo), sv(x.cat), false)
            sleep(250)
        end for
    end if
    return { ok: true }
end function

' Devolve a lista guardada se ainda estiver nova (menos de 10 min); senão baixa de novo. invalid se não deu.
function aquecerUma(s as Object, tipo as String, cat as String, ehCats as Boolean) as Dynamic
    q = { tipo: tipo, cat: cat, modo: "cache" }
    r = opLista(s, q, ehCats)
    if r.ok = true and r.velho <> true then return r.lista
    q.modo = "rede"
    r2 = opLista(s, q, ehCats)
    if r2.ok = true then return r2.lista
    if r.ok = true then return r.lista
    return invalid
end function
