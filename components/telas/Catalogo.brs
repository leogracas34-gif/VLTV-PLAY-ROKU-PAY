' VLTV Play - Roku | Filmes e Séries igual ao da LG: categorias 380 | grade 1390 com 6 capas por linha e caixa de pesquisa.
' Cima/baixo nas categorias só movem o destaque; OK abre na grade; direita entra na grade aberta.

sub iniciar()
    carregarI18n()
    m.tipo = sv(m.top.args.tipo)
    m.cats = []
    m.itens = []
    m.foco = "cat"
    m.modoBusca = false
    m.catAplicada = -1
    m.falhaCats = false
    m.indicePronto = false
    m.indiceFalhou = false
    titulo = "Filmes"
    if m.tipo = "series" then titulo = "Séries"
    vkFundo(m.top)
    m.pc = vkPainel(m.top, 60, 60, 380, 960, tx(titulo), true)
    m.pg = vkPainel(m.top, 470, 60, 1390, 960, "", true)
    m.lc = vkLista(m.pc.grupo, 23, 83, 334, 850, 84, 6, 27)
    m.grade = vkGrade(m.pg.grupo, 33, 89, 1338, 844, 6, 206, 296, 68, 14, 12, 25)
    m.grade.ativo = false
    ' caixa de pesquisa
    m.bx = vkCaixa(m.pg.grupo, 33, 87, 1324, 76, 16, 3, 6)
    vkPintar(m.bx, cBorda(), cPainel2(), false)
    vkImg(m.bx.grupo, 22, 20, 36, 36, "i_lupa", cBranco())
    m.bxTxt = vkTxt(m.bx.grupo, 76, 0, 1220, 76, "", 32, false, cBranco(), "left")
    m.bx.grupo.visible = false
    m.status = vkTxt(m.pg.grupo, 45, 173, 1300, 34, "", 24, false, cSuave(), "left")
    m.vazio = vkTxtM(m.pg.grupo, 39, 113, 1300, 200, "", 30, false, cSuave(), 4, "left")
    m.vazio.visible = false
    m.msgVazio = "Nenhum título nesta categoria."
    posicionar()

    vkListaItens(m.lc, [{ msg: true, nome: tx("Carregando categorias...") }])
    chamar("ApiTask", "cats", { tipo: m.tipo, modo: "cache" }, "aoCats")
    m.modoCats = "cache"
    ' O índice da pesquisa é grande: começa só depois de a tela já estar mostrando os títulos (ou quando a pesquisa for usada).
    m.memItens = {}
    m.tAq = uiNo(m.top, "Timer", { repeat: false, duration: 1.5 })
    m.tAq.observeField("fire", "aquecerVizinhas")
    m.indiceIniciado = false
    m.tIndice = uiNo(m.top, "Timer", { repeat: false, duration: 5 })
    m.tIndice.observeField("fire", "iniciarIndiceAuto")
    if cfg().preAquecer = true then m.tIndice.control = "start"
    m.top.setFocus(true)
end sub

sub iniciarIndice()
    ' Toda vez que a pesquisa é aberta/usada, pergunta à VPS se há títulos novos (no máx. 1 vez por minuto).
    ' Sem novidade nada é baixado; com novidade baixa só os novos. Enquanto isso a pesquisa usa o que já está guardado.
    if m.indiceRodando = true then return
    if m.indiceIniciado = true and nowSec() - iv(m.indiceT) < 60 then return
    m.indiceIniciado = true
    m.indiceT = nowSec()
    s = sessaoLer()
    if s <> invalid and s.modo <> "m3u" then
        m.indiceRodando = true
        chamar("IndexTask", "preparar", { tipo: m.tipo }, "aoIndice")
    else
        m.indiceFalhou = true
    end if
end sub

sub retomar()
    progressoInvalidar()   ' voltou do player/detalhe: "Continuar assistindo" pode ter mudado
    m.top.setFocus(true)
end sub

sub focar()
    m.top.setFocus(true)
end sub

sub encerrar()
    m.tAq.control = "stop"
    m.tIndice.control = "stop"
end sub

' Parado numa categoria, a TV já baixa (e guarda) as vizinhas: o OK delas fica instantâneo.
sub agendarAquecer()
    m.tAq.control = "stop"
    m.tAq.control = "start"
end sub

sub aquecerVizinhas()
    if cfg().preAquecer <> true then return   ' pré-carga em segundo plano desligada (config.json: "preAquecer": true liga)
    if m.cats.Count() = 0 or m.catAplicada < 0 then return
    pedidos = []
    for each d in [1, -1, 2]
        i = m.catAplicada + d
        if i >= 0 and i < m.cats.Count() then
            c = m.cats[i]
            if c.especial = invalid and c.adulta <> true then pedidos.Push({ tipo: m.tipo, cat: sv(c.category_id) })
        end if
    end for
    if pedidos.Count() > 0 then chamar("ApiTask", "aquecer", { cats: pedidos }, "aoAquecido")
end sub

sub aoAquecido(ev as Object)
    chamarFim(ev)
end sub

' Posição da grade (desce quando a caixa de pesquisa aparece).
sub posicionar()
    y = 89
    h = 844
    if m.modoBusca then
        y = 173
        h = 760
        if m.status.text <> "" then
            y = 211
            h = 722
        end if
    end if
    m.grade.grupo.translation = [33, y]
    m.grade.grupo.clippingRect = [0, 0, 1338, h]
    m.bx.grupo.visible = m.modoBusca
    m.status.visible = m.modoBusca
end sub

sub pintarBusca()
    if m.foco = "busca" then
        vkPintar(m.bx, cBranco(), cPainel2(), true)
        m.bx.glow.opacity = 0.5
    else
        vkPintar(m.bx, cBorda(), cPainel2(), false)
    end if
    if sv(m.ultimaBusca) = "" then
        m.bxTxt.text = tx("Digite o nome e aperte OK para abrir o teclado")
        m.bxTxt.color = cSuave()
    else
        m.bxTxt.text = m.ultimaBusca
        m.bxTxt.color = cBranco()
    end if
end sub

sub trocarFoco(novo as String)
    m.foco = novo
    m.lc.ativo = (novo = "cat")
    m.grade.ativo = (novo = "grade")
    vkListaDesenhar(m.lc)
    vkGradeDesenhar(m.grade)
    pintarBusca()
end sub

' ── Categorias ──────────────────────────────────────────────────────
function categoriaTrancada(c as Dynamic) as Boolean
    if c = invalid then return false
    return c.adulta = true and parentalBloqueando()
end function

sub desenharCats()
    itens = []
    i = 0
    for each c in m.cats
        if c.especial = "busca" then
            it = { nome: tx("Pesquisar"), icone: "pkg:/images/ui/i_lupa.png", iconeW: 34, iconeH: 34, iconeCor: cBranco() }
        else if c.especial = "fav" then
            it = { nome: tx("Favoritos"), icone: "pkg:/images/ui/i_estrela.png", iconeW: 34, iconeH: 34, iconeCor: cOuro() }
        else if c.especial = "cont" then
            it = { nome: tx("Continuar assistindo"), icone: "pkg:/images/ui/i_play.png", iconeW: 34, iconeH: 34, iconeCor: cBranco() }
        else
            nome = sv(c.category_name)
            if idiomaEn() then nome = trCat(nome)
            it = { nome: nome }
            if categoriaTrancada(c) then it.cad = true
        end if
        if i = m.catAplicada then it.marca = "claro"
        itens.Push(it)
        i = i + 1
    end for
    idx = m.lc.idx
    vkListaItens(m.lc, itens)
    vkListaIr(m.lc, idx)
end sub

sub aoCats(ev as Object)
    chamarFim(ev)
    r = ev.getData()
    if r.ok = true then
        primeira = (m.cats.Count() = 0)
        cats = [{ category_name: "Pesquisar", especial: "busca" }, { category_name: "Favoritos", especial: "fav" }]
        if continuarAssistindo(m.tipo).Count() > 0 then cats.Push({ category_name: "Continuar assistindo", especial: "cont" })
        m.nEsp = cats.Count()
        for each c in filtrarCategoriasParental(r.lista)
            cats.Push(c)
        end for
        m.cats = cats
        m.falhaCats = false
        desenharCats()
        if primeira and cats.Count() > m.nEsp then
            i = m.nEsp
            while i < cats.Count() - 1 and categoriaTrancada(cats[i])
                i = i + 1
            end while
            if not categoriaTrancada(cats[i]) then
                vkListaIr(m.lc, i)
                abrirCategoria(i)
            end if
        end if
        ' Guardado de menos de 10 min: não baixa de novo (abre mais rápido).
        if m.modoCats = "cache" and r.velho = true then
            m.modoCats = "rede"
            chamar("ApiTask", "cats", { tipo: m.tipo, modo: "rede" }, "aoCats")
        end if
    else if m.modoCats = "cache" then
        m.modoCats = "rede"
        chamar("ApiTask", "cats", { tipo: m.tipo, modo: "rede" }, "aoCats")
    else if m.cats.Count() = 0 then
        m.falhaCats = true
        vkListaItens(m.lc, [{ msg: true, nome: tx("Não foi possível carregar as categorias. Pressione OK para tentar de novo.") }])
    end if
end sub

sub aoIndice(ev as Object)
    chamarFim(ev)
    r = ev.getData()
    m.indiceRodando = false
    if r.ok = true then
        m.indicePronto = true
        ' chegaram títulos novos com a pesquisa já na tela: refaz a busca atual
        if (r.estado = "novos" or r.estado = "pronto") and m.buscaPendente = invalid and m.modoBusca = true and Len(sv(m.ultimaBusca)) >= 2 then
            buscar(m.ultimaBusca)
        end if
    else if m.indicePronto <> true then
        m.indiceFalhou = true
    end if
    if m.buscaPendente <> invalid then
        q = m.buscaPendente
        m.buscaPendente = invalid
        if m.indicePronto then
            buscar(q)
        else
            mostrarMsg("A pesquisa não está disponível agora. Use as categorias.")
        end if
    end if
end sub

' OK numa categoria
sub escolherCategoria()
    if m.falhaCats then
        m.falhaCats = false
        vkListaItens(m.lc, [{ msg: true, nome: tx("Carregando categorias...") }])
        chamar("ApiTask", "cats", { tipo: m.tipo, modo: "rede" }, "aoCats")
        m.modoCats = "rede"
        return
    end if
    i = m.lc.idx
    c = m.cats[i]
    if categoriaTrancada(c) then
        uiSenha("Categoria +18", "Digite a senha para abrir.", senhaCategoriaOk)
        return
    end if
    abrirCategoria(i)
end sub

sub senhaCategoriaOk()
    desenharCats()
    abrirCategoria(m.lc.idx)
end sub

sub abrirCategoria(i as Integer)
    c = m.cats[i]
    if c.especial = "busca" then
        iniciarIndice()
        m.catAplicada = i
        m.modoBusca = true
        m.itens = []
        m.status.text = ""
        m.pg.titulo.text = tx("Pesquisar")
        desenharCats()
        mostrarItens([], "Digite o nome e aperte OK na caixa de pesquisa.")
        posicionar()
        trocarFoco("busca")
        return
    end if
    m.modoBusca = false
    m.catAplicada = i
    desenharCats()
    posicionar()
    if c.especial = "fav" then
        m.pg.titulo.text = tx("Favoritos")
        lista = []
        for each f in favoritosDaConta(m.tipo)
            lista.Push({ id: sv(f.id), nome: sv(f.nome), capa: sv(f.capa), ext: sv(f.ext), cat: sv(f.cat) })
        end for
        mostrarItens(lista, "Nenhum favorito ainda. No detalhe, escolha Minha lista.")
    else if c.especial = "cont" then
        m.pg.titulo.text = tx("Continuar assistindo")
        lista = []
        for each r in continuarAssistindo(m.tipo)
            pct = 0
            if r.dur > 0 then pct = Int(r.pos * 100 / r.dur)
            lista.Push({ id: sv(r.tid), nome: sv(r.nome), capa: sv(r.capa), ext: sv(r.ext), cat: "", pct: pct })
        end for
        mostrarItens(lista, "Nada para continuar assistindo.")
    else
        m.catAtual = c
        m.catAdulta = (c.adulta = true)
        nome = sv(c.category_name)
        if idiomaEn() then nome = trCat(nome)
        m.pg.titulo.text = nome
        ' Já aberta há pouco nesta tela: aparece na hora, sem ler arquivo.
        mem = m.memItens[sv(c.category_id)]
        if mem <> invalid and not m.catAdulta then
            if nowSec() - mem.t < 600 then
                m.reqItens = m.catAplicada
                mostrarItens(mem.lista, "Nenhum título nesta categoria.")
                agendarAquecer()
                return
            end if
        end if
        mostrarMsg("Carregando...")
        m.modoItens = "cache"
        m.reqItens = m.catAplicada
        chamar("ApiTask", "itens", { tipo: m.tipo, cat: sv(c.category_id), modo: "cache" }, "aoItens")
    end if
end sub

sub aoItens(ev as Object)
    chamarFim(ev)
    if m.reqItens <> m.catAplicada or m.modoBusca then return
    r = ev.getData()
    if r.ok = true then
        lista = []
        for each x in filtrarItensParental(r.lista, m.catAdulta)
            lista.Push(normalizarItem(x))
        end for
        igual = (m.modoItens = "rede" and m.itens.Count() = lista.Count())
        if not igual then mostrarItens(lista, "Nenhum título nesta categoria.")
        if not m.catAdulta and lista.Count() > 0 then
            if m.memItens.Count() > 8 then m.memItens = {}
            m.memItens[sv(m.catAtual.category_id)] = { lista: lista, t: nowSec() }
        end if
        agendarAquecer()
        if m.modoItens = "cache" and r.velho = true then
            m.modoItens = "rede"
            chamar("ApiTask", "itens", { tipo: m.tipo, cat: sv(m.catAtual.category_id), modo: "rede" }, "aoItens")
        end if
    else if m.modoItens = "cache" then
        m.modoItens = "rede"
        chamar("ApiTask", "itens", { tipo: m.tipo, cat: sv(m.catAtual.category_id), modo: "rede" }, "aoItens")
    else
        mostrarMsg("Não foi possível carregar os títulos.")
    end if
end sub

function normalizarItem(x as Object) as Object
    if m.tipo = "series" then
        return { id: sv(x.series_id), nome: sv(x.name), capa: urlImagem(x.cover), ext: "", cat: sv(x.category_id) }
    end if
    ext = sv(x.container_extension)
    if sv(x.url) <> "" then ext = sv(x.url)   ' lista M3U: o endereço do vídeo vai no lugar da extensão
    return { id: sv(x.stream_id), nome: sv(x.name), capa: urlImagem(x.stream_icon), ext: ext, cat: sv(x.category_id) }
end function

sub mostrarMsg(texto as String)
    m.itens = []
    vkGradeItens(m.grade, [])
    m.vazio.text = tx(texto)
    m.vazio.visible = true
    m.vazio.translation = [39, 113]
    if m.modoBusca then m.vazio.translation = [39, 250]
end sub

sub mostrarItens(lista as Object, vazio as String)
    m.itens = lista
    if lista.Count() = 0 then
        mostrarMsg(vazio)
        return
    end if
    m.vazio.visible = false
    vis = []
    n = 0
    for each x in lista
        n = n + 1
        if n > 600 then exit for
        vis.Push({ nome: limparTitulo(x.nome), capa: x.capa, pct: x.pct })
    end for
    vkGradeItens(m.grade, vis)
end sub

' ── Pesquisa ────────────────────────────────────────────────────────
sub tecladoBusca(texto as String)
    q = texto.Trim()
    m.ultimaBusca = q
    pintarBusca()
    if Len(q) < 2 then
        mostrarMsg("Digite pelo menos 2 letras.")
        return
    end if
    iniciarIndice()
    if m.indiceFalhou and not m.indicePronto then
        mostrarMsg("A pesquisa não está disponível agora. Use as categorias.")
        return
    end if
    if not m.indicePronto then
        m.buscaPendente = q
        mostrarMsg("Preparando a pesquisa. Na primeira vez pode levar alguns minutos; depois fica pronta na hora.")
        return
    end if
    buscar(q)
end sub

sub buscar(q as String)
    mostrarMsg("Buscando...")
    t = chamar("IndexTask", "buscar", { tipo: m.tipo, q: q, limite: 150 }, "aoBusca")
    marcarPedido("busca", t)
end sub

sub aoBusca(ev as Object)
    if not pedidoAtual("busca", ev) then return
    r = ev.getData()
    if r.ok <> true then
        mostrarMsg("A pesquisa não está disponível agora. Use as categorias.")
        return
    end if
    lista = []
    for each x in r.itens
        lista.Push({ id: sv(x.id), nome: sv(x.nome), capa: urlImagem(x.capa), ext: sv(x.ext), cat: sv(x.cat) })
    end for
    m.status.text = Str(lista.Count()).Trim() + " " + tx("resultados")
    posicionar()
    mostrarItens(lista, "Nada encontrado.")
    if lista.Count() > 0 then trocarFoco("grade")
end sub

' ── Abrir título ────────────────────────────────────────────────────
sub abrirItem()
    i = m.grade.idx
    if i < 0 or i >= m.itens.Count() then return
    x = m.itens[i]
    uiAcao("abrir", { tela: "Detalhe", args: { tipo: m.tipo, id: x.id, nome: x.nome, capa: x.capa, ext: x.ext, cat: x.cat } })
end sub

' ── Teclas ──────────────────────────────────────────────────────────
sub voltarParaCategorias()
    if m.catAplicada >= 0 then vkListaIr(m.lc, m.catAplicada)
    trocarFoco("cat")
end sub

function onKeyEvent(tecla as String, pressionou as Boolean) as Boolean
    if not pressionou then return false
    if tecla = "back" then
        if m.foco <> "cat" then
            voltarParaCategorias()
            return true
        end if
        return false
    end if
    if m.foco = "cat" then
        if tecla = "up" then
            if m.lc.idx > 0 then vkListaIr(m.lc, m.lc.idx - 1)
        else if tecla = "down" then
            vkListaIr(m.lc, m.lc.idx + 1)
        else if tecla = "OK" then
            escolherCategoria()
        else if tecla = "right" then
            if m.modoBusca then
                if m.catAplicada >= 0 then vkListaIr(m.lc, m.catAplicada)
                if m.itens.Count() > 0 then trocarFoco("grade") else trocarFoco("busca")
            else if m.catAplicada >= 0 and m.itens.Count() > 0 then
                vkListaIr(m.lc, m.catAplicada)
                trocarFoco("grade")
            end if
        else
            return false
        end if
        return true
    else if m.foco = "busca" then
        if tecla = "down" then
            if m.itens.Count() > 0 then trocarFoco("grade")
        else if tecla = "left" then
            voltarParaCategorias()
        else if tecla = "OK" then
            uiTeclado("Pesquisar", "Digite parte do nome.", sv(m.ultimaBusca), false, tecladoBusca)
        end if
        return true
    end if
    ' grade
    if tecla = "OK" then
        if m.itens.Count() = 0 then
            if not m.modoBusca and m.catAplicada >= 0 then abrirCategoria(m.catAplicada)
        else
            abrirItem()
        end if
        return true
    else if vkEhSeta(tecla) then
        if m.itens.Count() = 0 then
            if tecla = "left" then voltarParaCategorias()
            return true
        end if
        if tecla = "up" and m.modoBusca and m.grade.idx < 6 then
            trocarFoco("busca")
            return true
        end if
        if not vkGradeTecla(m.grade, tecla) then
            if tecla = "left" then voltarParaCategorias()
        end if
        return true
    end if
    return false
end function

sub iniciarIndiceAuto()
    iniciarIndice()
end sub
