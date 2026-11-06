' VLTV Play - Roku | Teclado na tela no visual do app (letras, números e símbolos de endereço).
' Aceita também o teclado do app Roku no celular (teclas "Lit_x").

sub iniciar()
    carregarI18n()
    a = m.top.args
    m.senha = (a.senha = true)
    m.texto = sv(a.atual)
    m.maius = false
    m.ver = false
    m.cursor = true
    m.fim = false

    uiNo(m.top, "Rectangle", { translation: [0, 0], width: 1920, height: 1080, color: "0x000000DB" })
    pw = 1550
    ph = 770
    px = 185
    py = 155
    painel = vkCaixa(m.top, px, py, pw, ph, 22, 3, 8)
    vkPintar(painel, cBorda(), cFundoPainel(), false)
    painel.glow.opacity = 0.18
    painel.glow.visible = true

    vkTxt(m.top, px + 50, py + 30, pw - 100, 52, tx(sv(a.titulo)), 38, true, cTexto(), "left")
    vkTxt(m.top, px + 50, py + 80, pw - 100, 36, tx(sv(a.dica)), 26, false, cSuave(), "left")

    campo = vkCaixa(m.top, px + 50, py + 130, pw - 100, 88, 14, 3, 6)
    vkPintar(campo, cClaro(), cFundoPainel(), true)
    m.campoTxt = vkTxt(m.top, px + 80, py + 130, pw - 160, 88, "", 38, false, cTexto(), "left")

    m.linhas = montarLinhas()
    m.teclas = []
    kw = 136
    kh = 84
    gap = 10
    x0 = px + 50 + 5
    y0 = py + 245
    for r = 0 to m.linhas.Count() - 1
        linha = m.linhas[r]
        for k = 0 to linha.Count() - 1
            t = linha[k]
            w = t.uw * kw + (t.uw - 1) * gap
            x = x0 + t.u0 * (kw + gap)
            y = y0 + r * (kh + gap)
            t.caixa = vkCaixa(m.top, x, y, w, kh, 14, 3, 6)
            t.rotulo = vkTxt(m.top, x, y, w, kh, "", 38, true, cTexto(), "center")
            t.w = w
        end for
    end for
    m.kr = 0
    m.kk = 0
    rotular()
    pintar()
    desenharCampo()
    m.pisca = uiNo(m.top, "Timer", { repeat: true, duration: 0.5 })
    m.pisca.observeField("fire", "piscar")
    m.pisca.control = "start"
    m.top.setFocus(true)
end sub

sub focar()
    m.top.setFocus(true)
end sub

function montarLinhas() as Object
    linhas = []
    r1 = []
    r2 = []
    r3 = []
    r4 = []
    r5 = []
    d = "1234567890"
    q = "qwertyuiop"
    for i = 0 to 9
        r1.Push({ id: Mid(d, i + 1, 1), u0: i, uw: 1 })
        r2.Push({ id: Mid(q, i + 1, 1), u0: i, uw: 1 })
    end for
    a = "asdfghjkl"
    for i = 0 to 8
        r3.Push({ id: Mid(a, i + 1, 1), u0: i, uw: 1 })
    end for
    r3.Push({ id: "@apagar", u0: 9, uw: 1 })
    r4.Push({ id: "@shift", u0: 0, uw: 1 })
    z = "zxcvbnm.-"
    for i = 0 to 8
        r4.Push({ id: Mid(z, i + 1, 1), u0: i + 1, uw: 1 })
    end for
    r5.Push({ id: ":", u0: 0, uw: 1 })
    r5.Push({ id: "/", u0: 1, uw: 1 })
    r5.Push({ id: "_", u0: 2, uw: 1 })
    r5.Push({ id: "@", u0: 3, uw: 1 })
    r5.Push({ id: "@espaco", u0: 4, uw: 2 })
    if m.senha then
        r5.Push({ id: "@ver", u0: 6, uw: 1 })
    else
        r5.Push({ id: "@limpar", u0: 6, uw: 1 })
    end if
    r5.Push({ id: "@cancelar", u0: 7, uw: 1 })
    r5.Push({ id: "@ok", u0: 8, uw: 2 })
    linhas.Push(r1)
    linhas.Push(r2)
    linhas.Push(r3)
    linhas.Push(r4)
    linhas.Push(r5)
    return linhas
end function

sub rotular()
    for each linha in m.linhas
        for each t in linha
            id = t.id
            rot = id
            tam = 38
            cor = cTexto()
            if Len(id) = 1 then
                if m.maius then rot = UCase(id)
            else
                tam = 24
                cor = cSuave()
                if id = "@apagar" then rot = tx("Apagar")
                if id = "@shift" then
                    rot = "Aa"
                    if m.maius then cor = cBranco()
                end if
                if id = "@espaco" then rot = tx("Espaço")
                if id = "@limpar" then rot = tx("Limpar")
                if id = "@ver" then
                    rot = tx("Ver")
                    if m.ver then rot = tx("Ocultar")
                end if
                if id = "@cancelar" then
                    rot = tx("Cancelar")
                    tam = 22
                end if
                if id = "@ok" then
                    rot = "OK"
                    tam = 34
                    cor = cBranco()
                end if
            end if
            t.rotulo.text = rot
            t.rotulo.font = vkFonte(tam, true)
            t.cor = cor
        end for
    end for
end sub

sub pintar()
    for r = 0 to m.linhas.Count() - 1
        linha = m.linhas[r]
        for k = 0 to linha.Count() - 1
            t = linha[k]
            if r = m.kr and k = m.kk then
                vkPintar(t.caixa, cBranco(), cDest(), true)
                t.caixa.glow.opacity = 0.5
                t.rotulo.color = cBranco()
            else
                fundo = cPainel2()
                if t.id = "@ok" then fundo = cDest()
                vkPintar(t.caixa, cBorda(), fundo, false)
                t.rotulo.color = t.cor
            end if
        end for
    end for
end sub

sub desenharCampo()
    t = m.texto
    if m.senha and not m.ver then
        p = ""
        for i = 1 to Len(t)
            p = p + Chr(8226)
        end for
        t = p
    end if
    if Len(t) > 44 then t = Chr(8230) + Right(t, 43)
    c = ""
    if m.cursor then c = "|"
    m.campoTxt.text = t + c
end sub

sub piscar()
    m.cursor = not m.cursor
    desenharCampo()
end sub

sub escrever(c as String)
    if Len(m.texto) >= 200 then return
    m.texto = m.texto + c
    desenharCampo()
end sub

sub apagar()
    if Len(m.texto) > 0 then m.texto = Left(m.texto, Len(m.texto) - 1)
    desenharCampo()
end sub

sub terminar(ok as Boolean)
    if m.fim then return
    m.fim = true
    m.pisca.control = "stop"
    m.top.resultado = { ok: ok, texto: m.texto.Trim() }
end sub

sub apertar()
    t = m.linhas[m.kr][m.kk]
    id = t.id
    if Len(id) = 1 then
        if m.maius then escrever(UCase(id)) else escrever(id)
        ' Depois de uma letra maiúscula volta para minúscula, como nos celulares.
        if m.maius and id >= "a" and id <= "z" then
            m.maius = false
            rotular()
            pintar()
        end if
    else if id = "@apagar" then
        apagar()
    else if id = "@shift" then
        m.maius = not m.maius
        rotular()
        pintar()
    else if id = "@espaco" then
        escrever(" ")
    else if id = "@limpar" then
        m.texto = ""
        desenharCampo()
    else if id = "@ver" then
        m.ver = not m.ver
        rotular()
        desenharCampo()
    else if id = "@cancelar" then
        terminar(false)
    else if id = "@ok" then
        terminar(true)
    end if
end sub

' Procura, na linha r, a tecla que cobre a posição u (em unidades).
function teclaEm(r as Integer, u as Float) as Integer
    linha = m.linhas[r]
    melhor = 0
    dist = 1000.0
    for k = 0 to linha.Count() - 1
        t = linha[k]
        if u >= t.u0 and u < t.u0 + t.uw then return k
        c = t.u0 + t.uw / 2
        d = Abs(c - u)
        if d < dist then
            dist = d
            melhor = k
        end if
    end for
    return melhor
end function

function onKeyEvent(tecla as String, pressionou as Boolean) as Boolean
    if not pressionou then return true
    if tecla = "back" then
        terminar(false)
        return true
    end if
    if tecla = "left" then
        if m.kk > 0 then m.kk = m.kk - 1
        pintar()
    else if tecla = "right" then
        if m.kk < m.linhas[m.kr].Count() - 1 then m.kk = m.kk + 1
        pintar()
    else if tecla = "up" or tecla = "down" then
        t = m.linhas[m.kr][m.kk]
        u = t.u0 + t.uw / 2
        nr = m.kr - 1
        if tecla = "down" then nr = m.kr + 1
        if nr >= 0 and nr < m.linhas.Count() then
            m.kr = nr
            m.kk = teclaEm(nr, u)
            pintar()
        end if
    else if tecla = "OK" then
        apertar()
    else if tecla = "rewind" or LCase(tecla) = "backspace" then
        apagar()
    else if LCase(tecla) = "enter" then
        terminar(true)
    else if Len(tecla) = 5 and Left(tecla, 4) = "Lit_" then
        escrever(Right(tecla, 1))
    end if
    return true
end function
