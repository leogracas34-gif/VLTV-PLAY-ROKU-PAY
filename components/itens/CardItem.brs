sub mudou()
    c = m.top.itemContent
    if c = invalid then return
    m.top.findNode("nome").text = c.title
    m.top.findNode("semCapa").text = c.title
    m.top.findNode("capa").uri = c.hdposterurl
    n = c.shortdescriptionline1
    m.top.findNode("nota").text = n
    m.top.findNode("faixaNota").visible = (n <> "" and n <> invalid)
    ' barra de progresso do "continuar assistindo" vem em description ("45" = 45%)
end sub

sub focou()
    m.top.findNode("borda").visible = m.top.itemHasFocus
end sub
