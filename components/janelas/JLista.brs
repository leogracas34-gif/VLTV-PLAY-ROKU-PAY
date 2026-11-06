' VLTV Play - Roku | Janela de escolha (áudio, legenda, opções do player) no visual do app.
' args: { titulo, itens: [textos], atual: índice marcado (verde) }  ->  resultado { indice } (-1 = voltou)

sub iniciar()
    carregarI18n()
    a = m.top.args
    m.fim = false
    n = a.itens.Count()
    nVis = n
    if nVis > 8 then nVis = 8
    h = 28 + 62 + nVis * 80 + 28
    w = 760
    x = Int((1920 - w) / 2)
    y = Int((1080 - h) / 2)
    uiNo(m.top, "Rectangle", { translation: [0, 0], width: 1920, height: 1080, color: "0x000000B3" })
    cx = vkCaixa(m.top, x, y, w, h, 20, 3, 6)
    vkPintar(cx, cClaro(), cFundoPainel(), false)
    vkTxt(m.top, x + 36, y + 28, w - 72, 50, tx(sv(a.titulo)), 32, false, cSuave(), "left")
    m.lista = vkLista(m.top, x + 24, y + 28 + 62, w - 48, nVis * 80, 76, 4, 30)
    itens = []
    for i = 0 to n - 1
        it = { nome: tx(sv(a.itens[i])) }
        if a.atual <> invalid then
            if i = a.atual then it.cor = cOk()
        end if
        itens.Push(it)
    end for
    if a.atual <> invalid and a.atual >= 0 then m.lista.idx = a.atual
    vkListaItens(m.lista, itens)
    vkListaIr(m.lista, m.lista.idx)
    m.top.setFocus(true)
end sub

sub focar()
    m.top.setFocus(true)
end sub

function onKeyEvent(tecla as String, pressionou as Boolean) as Boolean
    if not pressionou then return true
    if tecla = "up" then
        vkListaIr(m.lista, m.lista.idx - 1)
    else if tecla = "down" then
        vkListaIr(m.lista, m.lista.idx + 1)
    else if tecla = "OK" then
        terminar(m.lista.idx)
    else if tecla = "back" or tecla = "options" then
        terminar(-1)
    end if
    return true
end function

sub terminar(i as Integer)
    if m.fim then return
    m.fim = true
    m.top.resultado = { indice: i }
end sub
