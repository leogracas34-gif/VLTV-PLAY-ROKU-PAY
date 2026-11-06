' VLTV Play - Roku | Janela de pergunta/aviso no visual do app ("Deseja sair?").
' args: { titulo, msg, botoes: [textos], perigo: índice do botão vermelho (-1 = nenhum), foco: índice inicial }

sub iniciar()
    carregarI18n()
    a = m.top.args
    m.botoes = a.botoes
    m.foco = 0
    if a.foco <> invalid then m.foco = a.foco
    m.perigo = -1
    if a.perigo <> invalid then m.perigo = a.perigo
    m.fim = false
    msg = tx(sv(a.msg))
    linhas = 1
    for each p in msg.Split(Chr(10))
        linhas = linhas + Int(Len(p) / 46)
    end for
    n = msg.Split(Chr(10)).Count()
    if n > 1 then linhas = linhas + n - 1
    if linhas > 8 then linhas = 8
    mh = linhas * 38
    bw = 340
    nb = m.botoes.Count()
    w = 880
    if nb * bw + (nb - 1) * 28 + 120 > w then w = nb * bw + (nb - 1) * 28 + 120
    h = 56 + 62 + 18 + mh + 44 + 92 + 52
    x = Int((1920 - w) / 2)
    y = Int((1080 - h) / 2)
    uiNo(m.top, "Rectangle", { translation: [0, 0], width: 1920, height: 1080, color: "0x000000BF" })
    cx = vkCaixa(m.top, x, y, w, h, 20, 3, 6)
    vkPintar(cx, cBorda(), cFundoPainel(), false)
    vkTxt(m.top, x + 30, y + 56, w - 60, 62, tx(sv(a.titulo)), 52, true, cTexto(), "center")
    vkTxtM(m.top, x + 60, y + 56 + 62 + 18, w - 120, mh, msg, 30, false, cSuave(), 8, "center")
    m.cx = []
    total = nb * bw + (nb - 1) * 28
    bx = x + Int((w - total) / 2)
    by = y + h - 52 - 92
    m.rot = []
    for i = 0 to nb - 1
        c = vkCaixa(m.top, bx + i * (bw + 28), by, bw, 92, 14, 3, 6)
        t = vkTxt(m.top, bx + i * (bw + 28), by, bw, 92, tx(sv(m.botoes[i])), 36, true, cBranco(), "center")
        m.cx.Push(c)
        m.rot.Push(t)
    end for
    pintar()
    m.top.setFocus(true)
end sub

sub focar()
    m.top.setFocus(true)
end sub

sub pintar()
    for i = 0 to m.cx.Count() - 1
        fundo = cPainel2()
        borda = cBorda()
        if i = m.perigo then
            fundo = cDest()
            borda = ""
        end if
        if i = m.foco then
            vkPintar(m.cx[i], cBranco(), fundo, true)
        else
            vkPintar(m.cx[i], borda, fundo, false)
        end if
    end for
end sub

function onKeyEvent(tecla as String, pressionou as Boolean) as Boolean
    if not pressionou then return true
    if tecla = "left" then
        if m.foco > 0 then m.foco = m.foco - 1
        pintar()
    else if tecla = "right" then
        if m.foco < m.cx.Count() - 1 then m.foco = m.foco + 1
        pintar()
    else if tecla = "OK" then
        terminar(m.foco)
    else if tecla = "back" then
        terminar(-1)
    end if
    return true
end function

sub terminar(i as Integer)
    if m.fim then return
    m.fim = true
    m.top.resultado = { indice: i }
end sub
