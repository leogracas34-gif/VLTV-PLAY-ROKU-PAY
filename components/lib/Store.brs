' VLTV Play - Roku | Armazenamento na TV.
'   Registro (pequeno e firme): login, listas, licença, idioma, controle parental.
'   Arquivos em cachefs:/ (maiores; ficam guardados entre aberturas): favoritos, progresso, índice, listas M3U.

function regGet(chave as String) as String
    s = CreateObject("roRegistrySection", "vltv")
    if s.Exists(chave) then return s.Read(chave)
    return ""
end function

sub regSet(chave as String, valor as String)
    s = CreateObject("roRegistrySection", "vltv")
    if valor = "" then
        s.Delete(chave)
    else
        s.Write(chave, valor)
    end if
    s.Flush()
end sub

function regJson(chave as String) as Dynamic
    t = regGet(chave)
    if t = "" then return invalid
    return ParseJson(t)
end function

sub regJsonSet(chave as String, v as Object)
    regSet(chave, FormatJson(v))
end sub

' ── Sessão (login em uso) ───────────────────────────────────────────
' modo: "usuario" | "parceiro" | "xtream" | "m3u"
function sessaoLer() as Dynamic
    s = regJson("sessao")
    if s = invalid then return invalid
    modo = sv(s.modo)
    if modo = "" then modo = "usuario"
    s.modo = modo
    if modo = "usuario" then s.dns = semBarraFinal(sv(m.global.config.gateway))
    if modo = "m3u"
        if sv(s.m3u) = "" then return invalid
        return s
    end if
    if modo = "parceiro" and sv(s.codigo) = "" then return invalid
    if sv(s.dns) = "" or sv(s.user) = "" or sv(s.pass) = "" then return invalid
    return s
end function

sub sessaoSalvar(d as Object)
    regJsonSet("sessao", d)
    regSet("aba", sv(d.modo))
end sub

sub sessaoLimpar()
    regSet("sessao", "")
end sub

function ultimaAba() as String
    a = regGet("aba")
    if a = "" then return "usuario"
    return a
end function

' Nome que o app manda para o backend da VPS (Top 10, créditos): nunca o DNS real nas contas VLTV.
function dominioBackend(s as Object) as String
    if s.modo = "usuario" and sv(s.painel) <> "" then return "painel:" + sv(s.painel)
    return sv(s.dns)
end function

' ── Minhas listas ───────────────────────────────────────────────────
function listasTodas() as Object
    a = regJson("listas")
    if a = invalid or Type(a) <> "roArray" then return []
    return a
end function

sub listasGravar(a as Object)
    regJsonSet("listas", a)
end sub

function listaAtivaId() as String
    return regGet("lista_ativa")
end function

function chaveLista(d as Object) as String
    modo = sv(d.modo)
    if modo = "m3u" then return "m3u|" + sv(d.m3u)
    if modo = "parceiro" then return "parceiro|" + UCase(sv(d.codigo)) + "|" + sv(d.user)
    if modo = "xtream" then return "xtream|" + sv(d.dns) + "|" + sv(d.user)
    return "usuario|" + sv(d.user)
end function

sub listaRegistrar(d as Object)
    id = chaveLista(d)
    todas = listasTodas()
    entrada = {
        id: id, modo: sv(d.modo), dns: sv(d.dns), user: sv(d.user), pass: sv(d.pass),
        codigo: sv(d.codigo), m3u: sv(d.m3u), parceiro: sv(d.parceiro), t: nowSec()
    }
    achou = false
    for i = 0 to todas.Count() - 1
        if todas[i].id = id
            todas[i] = entrada
            achou = true
        end if
    end for
    if not achou then todas.Push(entrada)
    while todas.Count() > 20
        velha = -1
        for j = 0 to todas.Count() - 1
            if todas[j].id <> id
                if velha = -1 then
                    velha = j
                else if todas[j].t < todas[velha].t then
                    velha = j
                end if
            end if
        end for
        if velha = -1 then exit while
        todas.Delete(velha)
    end while
    listasGravar(todas)
    regSet("lista_ativa", id)
end sub

sub listaRemover(id as String)
    saida = []
    for each e in listasTodas()
        if e.id <> id then saida.Push(e)
    end for
    listasGravar(saida)
    if listaAtivaId() = id then regSet("lista_ativa", "")
end sub

function hostDe(u as String) as String
    t = u
    p = Instr(1, t, "://")
    if p > 0 then t = Mid(t, p + 3)
    p = Instr(1, t, "/")
    if p > 0 then t = Left(t, p - 1)
    return t
end function

' Nome e tipo mostrados na tela de listas.
function rotuloLista(e as Object) as Object
    modo = sv(e.modo)
    if modo = "m3u" then
        return { titulo: hostDe(sv(e.m3u)), tipo: "Lista M3U  •  link: " + sv(e.m3u) }
    else if modo = "parceiro" then
        nome = sv(e.user)
        if sv(e.parceiro) <> "" then nome = nome + "  •  " + sv(e.parceiro)
        return { titulo: nome, tipo: "Xtream  •  código de parceiro: " + UCase(sv(e.codigo)) }
    else if modo = "xtream" then
        return { titulo: sv(e.user) + "  •  " + hostDe(sv(e.dns)), tipo: "Xtream  •  DNS: " + sv(e.dns) }
    end if
    return { titulo: sv(e.user), tipo: "Usuário e senha" }
end function

function grupoDaLista(e as Object) as String
    if e.modo = "parceiro" then return "xtream"
    return sv(e.modo)
end function

' ── Arquivos ────────────────────────────────────────────────────────
function caminhoCache(nome as String) as String
    return "cachefs:/vltv_" + nome
end function

function arqExiste(caminho as String) as Boolean
    return CreateObject("roFileSystem").Exists(caminho)
end function

sub arqApagar(caminho as String)
    fs = CreateObject("roFileSystem")
    if fs.Exists(caminho) then fs.Delete(caminho)
end sub

' Apaga o que for cache (índice, listas M3U, textos). Favoritos e progresso ficam.
sub limparCacheTudo()
    fs = CreateObject("roFileSystem")
    lista = fs.GetDirectoryListing("cachefs:/")
    if lista = invalid then return
    for each nome in lista
        if startsWith(nome, "vltv_") and not startsWith(nome, "vltv_fav") and not startsWith(nome, "vltv_prog") and not startsWith(nome, "vltv_cred") then
            fs.Delete("cachefs:/" + nome)
        end if
    end for
end sub

' ── Favoritos ─────────────────────────────────────────────────────
' Item: { t: "filmes"|"series"|"canais", id, nome, capa, ext }. Guardados por conta (dono).
' Guardado por 3 segundos: a conta em uso quase nunca muda e ler o registro + JSON a cada chamada deixava as telas lentas.
function donoConta() as String
    agora = nowSec()
    if m.donoCache <> invalid and agora - m.donoCacheT <= 3 then return m.donoCache
    s = sessaoLer()
    d = ""
    if s <> invalid then d = chaveLista(s)
    m.donoCache = d
    m.donoCacheT = agora
    return d
end function

function favoritosTodos() as Object
    v = lerJsonArq(caminhoCache("fav.json"))
    if v = invalid or not isAA(v) then return {}
    return v
end function

function favoritosDaConta(tipo as String) as Object
    todos = favoritosTodos()
    chave = donoConta() + "#" + tipo
    if todos[chave] = invalid then return []
    return todos[chave]
end function

function ehFavorito(tipo as String, id as String) as Boolean
    for each f in favoritosDaConta(tipo)
        if sv(f.id) = id then return true
    end for
    return false
end function

' Liga/desliga. Devolve true se ficou favorito.
function alternarFavorito(tipo as String, item as Object) as Boolean
    todos = favoritosTodos()
    chave = donoConta() + "#" + tipo
    lista = todos[chave]
    if lista = invalid then lista = []
    id = sv(item.id)
    saida = []
    existia = false
    for each f in lista
        if sv(f.id) = id then
            existia = true
        else
            saida.Push(f)
        end if
    end for
    if not existia
        novo = { id: id, nome: sv(item.nome), capa: sv(item.capa), ext: sv(item.ext), cat: sv(item.cat) }
        saida.Unshift(novo)
    end if
    todos[chave] = saida
    gravarJsonArq(caminhoCache("fav.json"), todos)
    return not existia
end function

' ── Continuar assistindo / posição salva ─────────────────────────────
' Chave por vídeo: "filme:ID" ou "ep:ID". Valor: { posicao, dur, t, tipo, tid, nome, capa, ... }.
' O arquivo é lido uma vez e fica na memória por 3 segundos (a tela de série lia o arquivo inteiro uma vez por episódio).
' progressoInvalidar() força ler de novo (ex.: ao voltar do player).
function progressoTodos() as Object
    agora = nowSec()
    if m.progCache <> invalid and agora - m.progCacheT <= 3 then return m.progCache
    v = lerJsonArq(caminhoCache("prog.json"))
    if v = invalid or not isAA(v) then v = {}
    m.progCache = v
    m.progCacheT = agora
    return v
end function

sub progressoInvalidar()
    m.progCache = invalid
    m.donoCache = invalid
end sub

function progressoDe(chave as String) as Dynamic
    todos = progressoTodos()
    return todos[donoConta() + "#" + chave]
end function

sub progressoSalvar(chave as String, reg as Object)
    todos = progressoTodos()
    todos[donoConta() + "#" + chave] = reg
    ' guarda no máximo 300 registros: os mais antigos saem
    if todos.Count() > 300
        velha = ""
        tvelha = 2147483647
        for each k in todos
            if todos[k].t < tvelha
                tvelha = todos[k].t
                velha = k
            end if
        end for
        if velha <> "" then todos.Delete(velha)
    end if
    gravarJsonArq(caminhoCache("prog.json"), todos)
end sub

sub progressoApagar(chave as String)
    todos = progressoTodos()
    todos.Delete(donoConta() + "#" + chave)
    gravarJsonArq(caminhoCache("prog.json"), todos)
end sub

' Itens de "Continuar assistindo" de um tipo ("filmes" | "series"), do mais novo para o mais antigo.
function continuarAssistindo(tipo as String) as Object
    todos = progressoTodos()
    dono = donoConta() + "#"
    saida = []
    vistas = {}
    for each k in todos
        if startsWith(k, dono)
            r = todos[k]
            if r.tipo = tipo and r.dur > 0 and r.pos > 20 and r.pos < r.dur - 90
                id = sv(r.tid)
                if vistas[id] = invalid or vistas[id].t < r.t then vistas[id] = r
            end if
        end if
    end for
    for each id in vistas
        saida.Push(vistas[id])
    end for
    saida.SortBy("t", "r")
    return saida
end function
