' VLTV Play - Roku | Minhas listas igual à da LG: painel 1300, abas de filtro, linhas com tipo, "Em uso" e "Remover".

sub iniciar()
    carregarI18n()
    vkFundo(m.top)
    m.painel = vkPainel(m.top, 310, 60, 1300, 960, tx("Minhas listas"), true)
    m.abas = []
    nomes = ["Todas", "Usuário", "Xtream", "Lista M3U"]
    m.grupos = ["todas", "usuario", "xtream", "m3u"]
    for i = 0 to 3
        b = vkBotao(m.painel.grupo, 23 + i * 317, 89, 303, 70, tx(nomes[i]), 27)
        m.abas.Push(b)
    end for
    m.lst = vkLista(m.painel.grupo, 23, 177, 1254, 690, 84, 6, 27)
    m.msg = vkTxt(m.painel.grupo, 36, 884, 1230, 56, "", 26, false, cSuave(), "left")
    m.zona = "lista"
    m.filtro = 0
    m.col = 0
    m.conf = ""
    ' começa na lista em uso
    todas = listasTodas()
    ativa = listaAtivaId()
    m.lst.idx = 0
    for i = 0 to todas.Count() - 1
        if todas[i].id = ativa then m.lst.idx = i
    end for
    aviso = sv(m.top.args.msg)
    if aviso <> "" then msgLista(tx(aviso), "")
    desenhar()
    m.top.setFocus(true)
end sub

sub retomar()
    desenhar()
    m.top.setFocus(true)
end sub

sub focar()
    m.top.setFocus(true)
end sub

sub encerrar()
end sub

sub msgLista(texto as String, tipo as String)
    m.msg.text = texto
    if tipo = "erro" then
        m.msg.color = cErro()
    else if tipo = "ok" then
        m.msg.color = cOk()
    else
        m.msg.color = cSuave()
    end if
end sub

function itensDaAba() as Object
    g = m.grupos[m.filtro]
    saida = []
    for each e in listasTodas()
        if g = "todas" or grupoDaLista(e) = g then saida.Push(e)
    end for
    return saida
end function

sub desenhar()
    m.linhas = itensDaAba()
    ativa = listaAtivaId()
    itens = []
    for each e in m.linhas
        r = rotuloLista(e)
        it = { nome: sv(r.titulo), subt: sv(r.tipo), rmv: tx("Remover") }
        if e.id = ativa then it.badge = tx("Em uso")
        if m.conf = e.id then it.rmv = tx("Confirmar?")
        itens.Push(it)
    end for
    itens.Push({ nome: "+  " + tx("Adicionar nova lista"), cor: cClaro(), neg: true })
    m.lst.col = m.col
    m.lst.semSel = (m.zona <> "lista")
    if m.lst.idx > itens.Count() - 1 then m.lst.idx = itens.Count() - 1
    vkListaItens(m.lst, itens)
    pintarAbas()
end sub

sub pintarAbas()
    for i = 0 to 3
        b = m.abas[i]
        if m.zona = "abas" and i = m.filtro then
            vkPintar(b.caixa, cBranco(), cDest(), true)
            b.caixa.glow.opacity = 0.5
            b.txt.color = cBranco()
        else if i = m.filtro then
            vkPintar(b.caixa, cClaro(), cPainel2(), false)
            b.txt.color = cBranco()
        else
            vkPintar(b.caixa, cBorda(), cPainel2(), false)
            b.txt.color = cSuave()
        end if
    end for
end sub

function ehLinhaDeLista(i as Integer) as Boolean
    return i < m.linhas.Count()
end function

sub ativar()
    l = m.lst
    if not ehLinhaDeLista(l.idx) then
        g = m.grupos[m.filtro]
        if g <> "todas" then regSet("aba", g)
        uiAcao("abrir", { tela: "Login", args: {} })
        return
    end if
    e = m.linhas[l.idx]
    if m.col = 1 then
        emUso = (e.id = listaAtivaId())
        if m.conf <> e.id then
            m.conf = e.id
            if emUso then
                msgLista(tx("Esta lista está em uso. Aperte OK de novo para remover e sair dela."), "")
            else
                msgLista(tx("Aperte OK de novo para remover esta lista."), "")
            end if
            desenhar()
            return
        end if
        listaRemover(sv(e.id))
        m.conf = ""
        m.col = 0
        if emUso then
            sessaoLimpar()
            uiAcao("sair", invalid)
            return
        end if
        msgLista(tx("Lista removida."), "ok")
        desenhar()
        return
    end if
    msgLista("", "")
    sessaoSalvar({ modo: sv(e.modo), dns: sv(e.dns), user: sv(e.user), pass: sv(e.pass), codigo: sv(e.codigo), m3u: sv(e.m3u), parceiro: sv(e.parceiro) })
    regSet("lista_ativa", sv(e.id))
    uiAcao("trocarlista", invalid)
end sub

function onKeyEvent(tecla as String, pressionou as Boolean) as Boolean
    if not pressionou then return false
    l = m.lst
    if m.zona = "abas" then
        if tecla = "left" and m.filtro > 0 then
            m.filtro = m.filtro - 1
            m.lst.idx = 0
            m.col = 0
            m.conf = ""
            desenhar()
        else if tecla = "right" and m.filtro < 3 then
            m.filtro = m.filtro + 1
            m.lst.idx = 0
            m.col = 0
            m.conf = ""
            desenhar()
        else if tecla = "down" or tecla = "OK" then
            m.zona = "lista"
            desenhar()
        else if tecla = "back" then
            return false
        end if
        return true
    end if
    if tecla = "up" then
        if l.idx = 0 then
            m.zona = "abas"
            m.col = 0
            desenhar()
        else
            l.idx = l.idx - 1
            m.col = 0
            m.conf = ""
            vkListaAjustar(l)
            desenhar()
        end if
    else if tecla = "down" then
        if l.idx < l.itens.Count() - 1 then
            l.idx = l.idx + 1
            m.col = 0
            m.conf = ""
            vkListaAjustar(l)
            desenhar()
        end if
    else if tecla = "right" then
        if ehLinhaDeLista(l.idx) then
            m.col = 1
            desenhar()
        end if
    else if tecla = "left" then
        if m.col = 1 then
            m.col = 0
            m.conf = ""
            desenhar()
        end if
    else if tecla = "OK" then
        ativar()
    else
        return false
    end if
    return true
end function
