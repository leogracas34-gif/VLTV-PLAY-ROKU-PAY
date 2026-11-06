' VLTV Play - Roku | Tela de licença com Roku Pay.
' Regra da Roku: nenhum link, site ou preço de fora. A compra é SÓ pelo Roku Pay (ChannelStore).
' Fluxo: getCatalog -> botões (anual / vitalícia / restaurar) -> doOrder -> getPurchases -> VPS valida e ativa.

sub iniciar()
    carregarI18n()
    lic = m.global.lic
    if lic = invalid or not isAA(lic) then lic = {}
    m.estado = sv(lic.estado)
    m.codigoTv = sv(lic.codigo)
    m.sem = (m.estado = "erro" or m.estado = "")
    m.bloq = (m.estado = "blocked")
    m.temOutra = (regGet("pendente") = "1" and not m.sem and not m.bloq)
    m.msg = sv(m.top.args.msg)
    m.ocupado = false
    m.btn = []
    m.acoes = []
    m.sel = 0
    m.preco = {}
    m.nomes = {}

    vkFundo(m.top)
    m.top.setFocus(true)

    m.loja = CreateObject("roSGNode", "ChannelStore")
    m.loja.observeField("catalog", "aoCatalogo")
    m.loja.observeField("orderStatus", "aoPedido")
    m.loja.observeField("purchases", "aoCompras")

    if m.bloq or m.sem then
        montar()
    else
        desenharBase(tx("Carregando..."))
        m.loja.command = "getCatalog"
    end if
end sub

sub desenharBase(texto as String)
    m.raiz = uiNo(m.top, "Group", {})
    vkImg(m.raiz, 706, 220, 508, 58, "logo_84", "")
    vkTxt(m.raiz, 160, 400, 1600, 58, tx(texto), 40, false, cSuave(), "center")
end sub

sub aoCatalogo(ev as Object)
    cat = ev.getData()
    if cat <> invalid then
        for i = 0 to cat.getChildCount() - 1
            it = cat.getChild(i)
            m.preco[sv(it.code)] = sv(it.cost)
            m.nomes[sv(it.code)] = sv(it.name)
        end for
    end if
    montar()
end sub

sub montar()
    if m.raiz <> invalid then m.top.removeChild(m.raiz)
    m.raiz = uiNo(m.top, "Group", {})
    m.btn = []
    m.acoes = []
    r = m.raiz

    if m.bloq then
        titulo = "Aparelho bloqueado"
        texto = "Este aparelho foi bloqueado. Fale com o suporte informando o código abaixo."
    else if m.sem then
        titulo = "Sem conexão com o servidor"
        texto = "Conecte a TV à internet e aperte OK para tentar de novo."
    else
        titulo = "Ative o seu VLTV Play"
        texto = "Para continuar assistindo, ative a licença desta TV."
        if m.msg <> "" then texto = m.msg
    end if

    anual = sv(cfg().rokuProdAnual)
    vital = sv(cfg().rokuProdVitalicio)
    temAnual = m.preco.doesExist(anual)
    temVital = m.preco.doesExist(vital)

    nBot = 0
    if not m.bloq and not m.sem then
        if temAnual then nBot = nBot + 1
        if temVital then nBot = nBot + 1
        nBot = nBot + 1   ' restaurar / tentar de novo
    else
        nBot = 1
    end if
    if m.temOutra then nBot = nBot + 1

    total = 100 + 40 + 58 + 18 + 45 + 20 + nBot * 114
    if m.bloq then total = total + 170
    y = 60 + Int((960 - total) / 2)
    if y < 40 then y = 40

    vkImg(r, 706, y + 8, 508, 58, "logo_84", "")
    y = y + 140
    vkTxt(r, 160, y, 1600, 58, tx(titulo), 48, true, cTexto(), "center")
    y = y + 76
    vkTxtM(r, 410, y, 1100, 90, tx(texto), 32, false, cSuave(), 2, "center")
    y = y + 100

    if m.bloq then
        cod = m.codigoTv
        if cod = "" then cod = "--------"
        vkTxt(r, 560, y, 800, 34, tx("Código desta TV"), 26, false, cSuave(), "center")
        y = y + 42
        vkTxt(r, 560, y, 800, 100, cod, 72, true, cTexto(), "center")
        y = y + 120
    end if

    if not m.bloq and not m.sem then
        if temAnual then
            m.btn.Push(vkBotao(r, 510, y, 900, 96, tx("Assinatura anual") + " - " + m.preco[anual], 38))
            m.acoes.Push("anual")
            y = y + 114
        end if
        if temVital then
            m.btn.Push(vkBotao(r, 510, y, 900, 96, tx("Licença vitalícia") + " - " + m.preco[vital], 38))
            m.acoes.Push("vitalicio")
            y = y + 114
        end if
        m.btn.Push(vkBotao(r, 510, y, 900, 96, tx("Já comprei - restaurar"), 38))
        m.acoes.Push("restaurar")
        y = y + 114
    else
        if m.sem then rot = "Tentar novamente" else rot = "Verificar de novo"
        m.btn.Push(vkBotao(r, 510, y, 900, 96, tx(rot), 38))
        m.acoes.Push("verificar")
        y = y + 114
    end if
    if m.temOutra then
        m.btn.Push(vkBotao(r, 510, y, 900, 96, tx("Usar outra lista"), 38))
        m.acoes.Push("lista")
    end if

    m.sel = 0
    pintar()
    m.top.setFocus(true)
end sub

sub pintar()
    for i = 0 to m.btn.Count() - 1
        b = m.btn[i]
        if i = m.sel then
            vkPintar(b.caixa, cBranco(), cDest(), true)
            b.caixa.glow.opacity = 0.5
        else
            vkPintar(b.caixa, "", cDest(), false)
        end if
    end for
end sub

sub retomar()
    m.top.setFocus(true)
end sub

sub focar()
    m.top.setFocus(true)
end sub

sub encerrar()
end sub

function onKeyEvent(tecla as String, pressionou as Boolean) as Boolean
    if not pressionou then return false
    if m.btn = invalid or m.btn.Count() = 0 then return false
    if tecla = "up" then
        if m.sel > 0 then m.sel = m.sel - 1
        pintar()
        return true
    else if tecla = "down" then
        if m.sel < m.btn.Count() - 1 then m.sel = m.sel + 1
        pintar()
        return true
    else if tecla = "OK" then
        if m.ocupado = true then return true
        acao = m.acoes[m.sel]
        if acao = "anual" then
            comprar(sv(cfg().rokuProdAnual))
        else if acao = "vitalicio" then
            comprar(sv(cfg().rokuProdVitalicio))
        else if acao = "restaurar" then
            m.modoCompras = "restaurar"
            m.ocupado = true
            m.loja.command = "getPurchases"
        else if acao = "verificar" then
            m.ocupado = true
            chamar("AuthTask", "licenca", {}, "aoLicenca")
        else if acao = "lista" then
            uiAcao("abrir", { tela: "Listas", args: { msg: "Escolha uma lista para entrar." } })
        end if
        return true
    end if
    return false
end function

' ── Compra ──────────────────────────────────────────────────────────
sub comprar(codigo as String)
    m.ocupado = true
    m.produtoComprado = codigo
    pedido = CreateObject("roSGNode", "ContentNode")
    item = pedido.createChild("ContentNode")
    item.addFields({ code: codigo, qty: 1 })
    m.loja.order = pedido
    m.loja.command = "doOrder"
end sub

sub aoPedido(ev as Object)
    st = ev.getData()
    ok = false
    if st <> invalid then
        if st.status = 1 then ok = true
    end if
    if ok then
        ' Compra feita: pega o transactionId (purchaseId) na lista de compras e manda para a VPS.
        m.modoCompras = "pos"
        m.loja.command = "getPurchases"
    else
        m.ocupado = false
        ' status <> 1: cancelou ou falhou. Não ativa nada.
    end if
end sub

sub aoCompras(ev as Object)
    lista = ev.getData()
    achada = invalid
    if lista <> invalid then
        for i = 0 to lista.getChildCount() - 1
            it = lista.getChild(i)
            cod = sv(it.code)
            if cod = sv(cfg().rokuProdAnual) or cod = sv(cfg().rokuProdVitalicio) then
                ' Vitalícia ganha da anual; entre iguais, a última da lista.
                if achada = invalid or cod = sv(cfg().rokuProdVitalicio) or sv(achada.code) <> sv(cfg().rokuProdVitalicio) then
                    achada = { code: cod, id: sv(it.purchaseId) }
                end if
            end if
        end for
    end if
    if achada = invalid or achada.id = "" then
        m.ocupado = false
        return
    end if
    chamar("AuthTask", "rokupay", { transacao: achada.id, produto: achada.code }, "aoLicenca")
end sub

sub aoLicenca(ev as Object)
    chamarFim(ev)
    m.ocupado = false
    r = ev.getData()
    estado = sv(r.estado)
    if estado = "active" or estado = "trial" then
        m.global.lic = r
        if regGet("pendente") = "1" then
            regSet("pendente", "")
            uiAcao("login", { msg: "Licença ativa! Aperte Entrar para abrir a lista." })
        else
            uiAcao("carregando", { ligado: true, texto: "Entrando..." })
            uiAcao("trocarlista", invalid)
        end if
    else if estado = "blocked" or estado = "erro" then
        m.global.lic = r
    end if
end sub
