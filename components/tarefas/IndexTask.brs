' VLTV Play - Roku | Índice de títulos (Filmes e Séries) para pesquisa.
' A VPS monta o catálogo inteiro; a TV baixa UMA vez e guarda num arquivo (nunca é apagado pelo app, só por
' "Limpar cache"). Ao abrir, a TV pergunta à VPS se há catálogo novo: sem novidade nada é baixado; com novidade
' baixa SÓ os títulos novos e junta ao que já está guardado. Uma vez por semana refaz o índice inteiro.
'   op "preparar" params { tipo }                        -> { ok, estado: "pronto"|"novos"|"igual"|"erro"|"sem_vps", total }
'   op "buscar"   params { tipo, q, limite }             -> { ok, itens: [{ id, nome, cat, ext, rating, capa }] }
'   op "achar"    params { tipo, nome }                  -> { ok, id, nome }   (título do banner no SEU painel)
sub init()
    m.top.functionName = "executar"
end sub

sub executar()
    p = m.top.params
    if p = invalid then p = {}
    op = m.top.op
    if op = "preparar" then
        m.top.result = prepararIndice(sv(p.tipo))
    else if op = "buscar" then
        m.top.result = buscarIndice(sv(p.tipo), sv(p.q), iv(p.limite))
    else if op = "achar" then
        m.top.result = acharIndice(sv(p.tipo), sv(p.nome))
    else
        m.top.result = { ok: false }
    end if
end sub

function arqIndice(tipo as String) as String
    return caminhoCache("idx_" + hashCurto(donoConta()) + "_" + tipo + ".tsv")
end function

function arqMeta(tipo as String) as String
    return caminhoCache("idx_" + hashCurto(donoConta()) + "_" + tipo + ".json")
end function

' ── Baixar e manter o índice ────────────────────────────────────────
function prepararIndice(tipo as String) as Object
    s = sessaoLer()
    if s = invalid or s.modo = "m3u" then return { ok: false, estado: "sem_vps" }
    arq = arqIndice(tipo)
    meta = lerJsonArq(arqMeta(tipo))
    local = (meta <> invalid and isAA(meta) and arqExiste(arq))
    desde = 0
    versao = ""
    if local then
        ' Uma vez por semana refaz tudo (pega também o que saiu do catálogo).
        if nowSec() - iv(meta.completoEm) < 86400 then
            versao = sv(meta.v)
            desde = iv(meta.maxadded)
        else
            local = false
        end if
    end if

    base = sv(s.dns) + "/player_api.php?username=" + urlEnc(sv(s.user)) + "&password=" + urlEnc(sv(s.pass)) + "&action=vltv_indice&tipo=" + tipo + "&formato=tsv"
    url = base
    if versao <> "" then url = url + "&v=" + urlEnc(versao)
    if desde > 0 then url = url + "&desde=" + Str(desde).Trim()

    ' A VPS pode estar montando o índice (resposta 202): pergunta de novo a cada 4 s, até uns 4 minutos.
    texto = ""
    for tentativa = 1 to 60
        r = httpSync(url, "GET", "", invalid, 120000)
        if r.status = 202 then
            sleep(4000)
        else if not r.ok then
            if local then return { ok: true, estado: "igual", total: iv(meta.total) }
            if r.status = 404 or r.status = 400 then return { ok: false, estado: "sem_vps" }
            return { ok: false, estado: "erro" }
        else
            texto = r.texto
            exit for
        end if
    end for
    if texto = "" then
        if local then return { ok: true, estado: "igual", total: iv(meta.total) }
        return { ok: false, estado: "erro" }
    end if

    ' Resposta em JSON: "mudou: false" (nada novo) ou formato desconhecido (gateway sem o índice novo).
    if Left(texto, 1) = "{" then
        j = ParseJson(texto)
        if isAA(j) and j.mudou = false and local then
            meta.t = nowSec()
            gravarJsonArq(arqMeta(tipo), meta)
            return { ok: true, estado: "igual", total: iv(meta.total) }
        end if
        if local then return { ok: true, estado: "igual", total: iv(meta.total) }
        return { ok: false, estado: "sem_vps" }
    end if
    if Left(texto, 1) <> "#" then
        if local then return { ok: true, estado: "igual", total: iv(meta.total) }
        return { ok: false, estado: "sem_vps" }
    end if

    ' Primeira linha: #v=HASH modo=tudo|novos completo=1 total=N maxadded=T
    fimCab = Instr(1, texto, Chr(10))
    cab = Left(texto, fimCab - 1)
    corpo = Mid(texto, fimCab + 1)
    texto = ""
    novo = { v: cabCampo(cab, "v"), total: iv(cabCampo(cab, "total")), maxadded: iv(cabCampo(cab, "maxadded")), t: nowSec() }
    modo = cabCampo(cab, "modo")
    completo = (cabCampo(cab, "completo") = "1")

    if modo = "novos" and local then
        ' Só o que é novo: junta ao que já está guardado.
        antigo = ReadAsciiFile(arq)
        if antigo = "" then return { ok: false, estado: "erro" }
        if Right(antigo, 1) <> Chr(10) then antigo = antigo + Chr(10)
        ' A VPS manda de novo as categorias (podem ter surgido novas) + só os títulos novos.
        iniNovo = inicioDasLinhas(corpo)
        iniAntigo = inicioDasLinhas(antigo)
        junto = Left(corpo, iniNovo - 1) + Mid(antigo, iniAntigo) + Mid(corpo, iniNovo)
        if not escreverAtomico(arq, junto) then return { ok: false, estado: "erro" }
        novo.completoEm = iv(meta.completoEm)
        if novo.maxadded = 0 then novo.maxadded = desde
        gravarJsonArq(arqMeta(tipo), novo)
        return { ok: true, estado: "novos", total: novo.total }
    end if

    if not escreverAtomico(arq, corpo) then return { ok: false, estado: "erro" }
    novo.completoEm = nowSec()
    if not completo then novo.completoEm = nowSec() - 86400 + 600   ' incompleto: refaz em 10 min
    gravarJsonArq(arqMeta(tipo), novo)
    return { ok: true, estado: "pronto", total: novo.total }
end function

function cabCampo(cab as String, nome as String) as String
    p = Instr(1, cab, nome + "=")
    if p = 0 then return ""
    ini = p + Len(nome) + 1
    fim = Instr(ini, cab, " ")
    if fim = 0 then fim = Len(cab) + 1
    return Mid(cab, ini, fim - ini)
end function

function escreverAtomico(caminho as String, texto as String) as Boolean
    tmp = caminho + ".tmp"
    if not WriteAsciiFile(tmp, texto) then return false
    fs = CreateObject("roFileSystem")
    if fs.Exists(caminho) then fs.Delete(caminho)
    return fs.Rename(tmp, caminho)
end function

' ── Pesquisa ──────────────────────────────────────────────────────
function splitTab(linha as String) as Object
    saida = []
    resto = linha
    while true
        p = Instr(1, resto, Chr(9))
        if p = 0 then exit while
        saida.Push(Left(resto, p - 1))
        resto = Mid(resto, p + 1)
    end while
    saida.Push(resto)
    return saida
end function

' "Filme 1 é bom" (texto da VPS, só ASCII) -> texto de verdade
function decodificarNome(s as String) as String
    if Instr(1, s, "\") = 0 then return s
    j = ParseJson("[""" + s + """]")
    if j <> invalid and j.Count() = 1 then return sv(j[0])
    return s
end function

' Categorias do índice: id -> { nome, adulta }
function lerCategoriasIndice(texto as String) as Object
    cats = {}
    posicao = 1
    while Mid(texto, posicao, 1) = "@"
        fim = Instr(posicao, texto, Chr(10))
        if fim = 0 then exit while
        campos = splitTab(Mid(texto, posicao + 1, fim - posicao - 1))
        if campos.Count() >= 2 then
            nome = decodificarNome(campos[1])
            cats[campos[0]] = { nome: nome, adulta: ehCatAdulta(nome) }
        end if
        posicao = fim + 1
    end while
    return cats
end function

function inicioDasLinhas(texto as String) as Integer
    posicao = 1
    while Mid(texto, posicao, 1) = "@"
        fim = Instr(posicao, texto, Chr(10))
        if fim = 0 then return posicao
        posicao = fim + 1
    end while
    return posicao
end function

function buscarIndice(tipo as String, q as String, limite as Integer) as Object
    arq = arqIndice(tipo)
    if not arqExiste(arq) then return { ok: false, semIndice: true }
    texto = ReadAsciiFile(arq)
    if texto = "" then return { ok: false, semIndice: true }
    if limite <= 0 then limite = 150

    consulta = norm(q)
    if consulta = "" then return { ok: true, itens: [] }
    palavras = []
    ancora = ""
    for each w in consulta.Split(" ")
        if w <> "" then
            palavras.Push(w)
            if Len(w) > Len(ancora) then ancora = w
        end if
    end for

    cats = lerCategoriasIndice(texto)
    bloqueando = parentalBloqueando()
    inicio = inicioDasLinhas(texto)
    comecam = []
    contidos = []
    tam = Len(texto)
    posicao = inicio
    hits = 0
    ultimaLinha = 0
    while hits < 40000
        achou = Instr(posicao, texto, ancora)
        if achou = 0 then exit while
        hits = hits + 1
        ' início e fim da linha onde caiu
        ini = achou
        while ini > inicio and Mid(texto, ini - 1, 1) <> Chr(10)
            ini = ini - 1
        end while
        fim = Instr(achou, texto, Chr(10))
        if fim = 0 then fim = tam + 1
        posicao = fim + 1
        if ini <> ultimaLinha then
            ultimaLinha = ini
            linha = Mid(texto, ini, fim - ini)
            tabu = Instr(1, linha, Chr(9))
            if tabu > 0 and achou - ini < tabu then   ' o trecho precisa estar no nome normalizado
                nomeNorm = Left(linha, tabu - 1)
                ok = true
                for each w in palavras
                    if Instr(1, nomeNorm, w) = 0 then
                        ok = false
                        exit for
                    end if
                end for
                if ok then
                    campos = splitTab(linha)
                    if campos.Count() >= 6 then
                        cat = campos[3]
                        adulto = false
                        if cats[cat] <> invalid and cats[cat].adulta then adulto = true
                        if not (bloqueando and adulto) then
                            item = { id: campos[1], nome: decodificarNome(campos[2]), cat: cat, ext: campos[4], rating: campos[5], adulta: adulto }
                            if Left(nomeNorm, Len(consulta)) = consulta then
                                comecam.Push(item)
                            else
                                contidos.Push(item)
                            end if
                            if comecam.Count() + contidos.Count() >= limite * 3 then exit while
                        end if
                    end if
                end if
            end if
        end if
    end while

    itens = []
    for each x in comecam
        if itens.Count() < limite then itens.Push(x)
    end for
    for each x in contidos
        if itens.Count() < limite then itens.Push(x)
    end for
    texto = ""

    ' Capas: a VPS manda só as dos títulos que vão aparecer.
    s = sessaoLer()
    if s <> invalid and itens.Count() > 0 then
        ids = []
        for each x in itens
            ids.Push(x.id)
        end for
        url = sv(s.dns) + "/player_api.php?username=" + urlEnc(sv(s.user)) + "&password=" + urlEnc(sv(s.pass)) + "&action=vltv_capas&tipo=" + tipo + "&ids=" + ids.Join(",")
        r = httpJson(url, 15000)
        if r.ok and isAA(r.json) and isAA(r.json.capas) then
            for each x in itens
                x.capa = sv(r.json.capas[x.id])
            end for
        end if
    end if
    return { ok: true, itens: itens }
end function

' Acha no seu painel o título que o banner mostra (nome igual depois de limpar). Devolve o primeiro.
function acharIndice(tipo as String, nome as String) as Object
    arq = arqIndice(tipo)
    if not arqExiste(arq) then return { ok: false, semIndice: true }
    texto = ReadAsciiFile(arq)
    alvo = norm(nome)
    if alvo = "" or texto = "" then return { ok: false }
    posicao = Instr(1, texto, Chr(10) + alvo + Chr(9))
    if posicao = 0 then return { ok: false }
    ini = posicao + 1
    fim = Instr(ini, texto, Chr(10))
    if fim = 0 then fim = Len(texto) + 1
    campos = splitTab(Mid(texto, ini, fim - ini))
    if campos.Count() < 6 then return { ok: false }
    return { ok: true, id: campos[1], nome: decodificarNome(campos[2]), cat: campos[3], ext: campos[4], rating: campos[5] }
end function
