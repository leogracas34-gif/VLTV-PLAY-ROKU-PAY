' VLTV Play - Roku | Tarefa do TMDB.
'   op "detalhe"   params { tipo: filmes|series, id, nome } -> { ok, titulo, sinopse, logo, fundo, tid }
'   op "destaque" params { tipo, tmdb (id do TMDB, opcional), nome }   -> { ok, titulo, sinopse, logo, fundo, capa, nota }
'   op "temporada" params { id, nome, numero }              -> { ok, eps: { "1": { titulo, imagem } } }
'   op "epg"       params { titulo }                        -> { ok, titulo, sinopse }
'   op "epgvarios" params { titulos: [..] }                 -> { ok, mapa: { titulo: { titulo, sinopse } } }
sub init()
    m.top.functionName = "executar"
end sub

sub executar()
    p = m.top.params
    if p = invalid then p = {}
    op = m.top.op
    if op = "detalhe" then
        r = tmdbDetalhe(sv(p.tipo), sv(p.id), sv(p.nome))
        if r = invalid then
            m.top.result = { ok: false }
        else
            r.ok = true
            m.top.result = r
        end if
    else if op = "destaque" then
        r = tmdbDestaque(sv(p.tipo), sv(p.tmdb), sv(p.nome))
        if r = invalid then
            m.top.result = { ok: false }
        else
            r.ok = true
            m.top.result = r
        end if
    else if op = "temporada" then
        e = tmdbTemporada(sv(p.id), sv(p.nome), sv(p.numero))
        if e = invalid then
            m.top.result = { ok: false }
        else
            m.top.result = { ok: true, eps: e }
        end if
    else if op = "epg" then
        r = tmdbEpg(sv(p.titulo))
        if r = invalid then
            m.top.result = { ok: false }
        else
            m.top.result = { ok: true, titulo: r.titulo, sinopse: r.sinopse }
        end if
    else if op = "epgvarios" then
        mapa = {}
        if isLista(p.titulos) then
            for each t in p.titulos
                r = tmdbEpg(sv(t))
                if r <> invalid then mapa[sv(t)] = r
            end for
        end if
        m.top.result = { ok: true, mapa: mapa }
    else
        m.top.result = { ok: false }
    end if
end sub
