' VLTV Play - Roku | Janela da senha dos pais (teclado numérico, criar senha, pergunta secreta, recuperar).
' args: { modo: "pedir" | "criar", titulo, sub }  ->  resultado { ok: true|false }

sub iniciar()
    carregarI18n()
    a = m.top.args
    m.fim = false
    m.digitos = ""
    m.pinNovo = ""
    m.qIdx = 0
    m.msgTxt = ""
    m.resp = ""
    uiNo(m.top, "Rectangle", { translation: [0, 0], width: 1920, height: 1080, color: "0x000000DB" })
    m.cont = uiNo(m.top, "Group", {})
    if sv(a.modo) = "criar" then
        m.fase = "novo1"
        mostrarTeclado("Criar nova senha", "Digite 4 números.", false)
    else
        m.fase = "pedir"
        t = sv(a.titulo)
        if t = "" then t = "Conteúdo protegido"
        s = sv(a.sub)
        if s = "" then s = "Digite a senha de 4 dígitos."
        mostrarTeclado(t, s, temPergunta())
    end if
    m.top.setFocus(true)
end sub

sub focar()
    m.top.setFocus(true)
end sub

sub limpar()
    while m.cont.getChildCount() > 0
        m.cont.removeChildIndex(0)
    end while
end sub

' ── Teclado numérico ────────────────────────────────────────────────
sub mostrarTeclado(titulo as String, sub1 as String, comEsqueci as Boolean)
    limpar()
    m.zona = "teclado"
    m.lin = 0
    m.col = 0
    m.comEsqueci = comEsqueci
    m.digitos = ""
    w = 760
    h = 44 + 48 + 10 + 36 + 28 + 30 + 22 + 4 * 90 + 36
    if comEsqueci then h = h + 66
    h = h + 56
    x = Int((1920 - w) / 2)
    y = Int((1080 - h) / 2)
    cx = vkCaixa(m.cont, x, y, w, h, 22, 3, 8)
    vkPintar(cx, cBorda(), cFundoPainel(), false)
    cx.glow.opacity = 0.18
    cx.glow.visible = true
    yy = y + 44
    vkTxt(m.cont, x, yy, w, 48, tx(titulo), 40, true, cTexto(), "center")
    yy = yy + 48 + 10
    vkTxtM(m.cont, x + 50, yy, w - 100, 36, tx(sub1), 26, false, cSuave(), 1, "center")
    yy = yy + 36 + 28
    m.pontos = []
    for i = 0 to 3
        c = vkCaixa(m.cont, x + Int(w / 2) - 2 * 58 + 14 + i * 58, yy, 30, 30, 15, 3, 4)
        m.pontos.Push(c)
    end for
    yy = yy + 30 + 22
    m.teclasPin = []
    rots = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "Apagar", "0", "Cancelar"]
    kx = x + 120
    for i = 0 to 11
        l = Int(i / 3)
        c = i mod 3
        cj = vkCaixa(m.cont, kx + c * 173, yy + l * 90, 160, 78, 14, 3, 6)
        tam = 36
        if i = 9 or i = 11 then tam = 24
        tt = vkTxt(m.cont, kx + c * 173, yy + l * 90, 160, 78, tx(rots[i]), tam, true, cTexto(), "center")
        m.teclasPin.Push({ caixa: cj, txt: tt, id: rots[i] })
    end for
    yy = yy + 4 * 90 + 6
    m.esq = invalid
    if comEsqueci then
        ew = 340
        m.esq = vkCaixa(m.cont, x + Int((w - ew) / 2), yy, ew, 56, 12, 2, 6)
        m.esqTxt = vkTxt(m.cont, x + Int((w - ew) / 2), yy, ew, 56, tx("Esqueci a senha"), 25, false, cSuave(), "center")
        yy = yy + 66
    end if
    m.msg = vkTxt(m.cont, x + 30, yy + 4, w - 60, 44, tx(m.msgTxt), 26, false, cErro(), "center")
    pintarPontos()
    pintarFoco()
end sub

sub pintarPontos()
    for i = 0 to 3
        if i < Len(m.digitos) then
            vkPintar(m.pontos[i], cClaro(), cClaro(), false)
        else
            vkPintar(m.pontos[i], cSuave(), cFundoPainel(), false)
        end if
    end for
end sub

sub pintarFoco()
    if m.zona = "teclado" or m.zona = "esqueci" then
        for i = 0 to 11
            t = m.teclasPin[i]
            if m.zona = "teclado" and i = m.lin * 3 + m.col then
                vkPintar(t.caixa, cBranco(), cDest(), true)
                t.txt.color = cBranco()
            else
                vkPintar(t.caixa, cBorda(), cPainel2(), false)
                if i = 9 or i = 11 then t.txt.color = cSuave() else t.txt.color = cTexto()
            end if
        end for
        if m.esq <> invalid then
            if m.zona = "esqueci" then
                vkPintar(m.esq, cBranco(), cDest(), true)
                m.esqTxt.color = cBranco()
            else
                vkPintar(m.esq, cBorda(), cFundoPainel(), false)
                m.esqTxt.color = cSuave()
            end if
        end if
    else
        for i = 0 to m.formItens.Count() - 1
            f = m.formItens[i]
            if i = m.formIdx then
                vkPintar(f.caixa, cBranco(), cDest(), true)
                if f.txt <> invalid then f.txt.color = cBranco()
            else
                vkPintar(f.caixa, cBorda(), cPainel2(), false)
                if f.txt <> invalid then
                    f.txt.color = cTexto()
                    if f.tipo = "ok" or f.tipo = "cancelar" then f.txt.color = cSuave()
                end if
            end if
        end for
    end if
end sub

sub mensagem(t as String)
    m.msgTxt = t
    m.msg.text = tx(t)
end sub

' ── Formulário (pergunta secreta) ───────────────────────────────────
sub mostrarForm(titulo as String, sub1 as String, escolher as Boolean)
    limpar()
    m.zona = "form"
    m.resp = ""
    w = 760
    h = 44 + 48 + 10 + 36 + 22 + 110 + 18 + 84 + 22 + 78 + 12 + 44 + 36
    x = Int((1920 - w) / 2)
    y = Int((1080 - h) / 2)
    cx = vkCaixa(m.cont, x, y, w, h, 22, 3, 8)
    vkPintar(cx, cBorda(), cFundoPainel(), false)
    cx.glow.opacity = 0.18
    cx.glow.visible = true
    yy = y + 44
    vkTxt(m.cont, x, yy, w, 48, tx(titulo), 40, true, cTexto(), "center")
    yy = yy + 48 + 10
    vkTxtM(m.cont, x + 50, yy, w - 100, 36, tx(sub1), 26, false, cSuave(), 1, "center")
    yy = yy + 36 + 22
    m.formItens = []
    pg = vkCaixa(m.cont, x + 50, yy, w - 100, 110, 14, 3, 6)
    if escolher then
        txt = Chr(9664) + "  " + perguntasSecretas()[m.qIdx] + "  " + Chr(9654)
        m.pergTxt = vkTxtM(m.cont, x + 70, yy + 8, w - 140, 94, txt, 28, false, cTexto(), 3, "left")
        m.formItens.Push({ caixa: pg, txt: m.pergTxt, tipo: "pergunta" })
    else
        m.pergTxt = vkTxtM(m.cont, x + 70, yy + 8, w - 140, 94, perguntaAtual(), 28, false, cTexto(), 3, "left")
        m.formItens.Push({ caixa: pg, txt: m.pergTxt, tipo: "fixa" })
    end if
    yy = yy + 110 + 18
    cr = vkCaixa(m.cont, x + 50, yy, w - 100, 84, 14, 3, 6)
    m.respTxt = vkTxt(m.cont, x + 76, yy, w - 152, 84, tx("Sua resposta"), 32, false, cSuave(), "left")
    m.formItens.Push({ caixa: cr, txt: m.respTxt, tipo: "texto" })
    yy = yy + 84 + 22
    rotOk = "Confirmar"
    if escolher then rotOk = "Salvar"
    c1 = vkCaixa(m.cont, x + 50, yy, 320, 78, 14, 3, 6)
    t1 = vkTxt(m.cont, x + 50, yy, 320, 78, tx(rotOk), 28, true, cSuave(), "center")
    c2 = vkCaixa(m.cont, x + w - 50 - 320, yy, 320, 78, 14, 3, 6)
    t2 = vkTxt(m.cont, x + w - 50 - 320, yy, 320, 78, tx("Cancelar"), 28, true, cSuave(), "center")
    m.formItens.Push({ caixa: c1, txt: t1, tipo: "ok" })
    m.formItens.Push({ caixa: c2, txt: t2, tipo: "cancelar" })
    yy = yy + 78 + 12
    m.msg = vkTxt(m.cont, x + 30, yy, w - 60, 44, tx(m.msgTxt), 26, false, cErro(), "center")
    m.formIdx = 1
    pintarFoco()
end sub

' ── Fluxo ───────────────────────────────────────────────────────────
sub digitar(d as String)
    if Len(m.digitos) >= 4 then return
    mensagem("")
    m.digitos = m.digitos + d
    pintarPontos()
    if Len(m.digitos) = 4 then
        m.espera = uiNo(m.top, "Timer", { repeat: false, duration: 0.15 })
        m.espera.observeField("fire", "aposPin")
        m.espera.control = "start"
    end if
end sub

sub aposPin()
    if m.fim then return
    if m.fase = "pedir" then
        if pinConfere(m.digitos) then
            terminar(true)
            return
        end if
        m.digitos = ""
        pintarPontos()
        mensagem("Senha incorreta.")
    else if m.fase = "novo1" then
        if m.digitos = "0000" then
            m.digitos = ""
            pintarPontos()
            mensagem("Escolha uma senha diferente de 0000.")
            return
        end if
        m.pinNovo = m.digitos
        m.fase = "novo2"
        m.msgTxt = ""
        mostrarTeclado("Confirmar senha", "Digite a mesma senha de novo.", false)
    else if m.fase = "novo2" then
        if m.digitos = m.pinNovo then
            m.fase = "perg"
            m.msgTxt = ""
            mostrarForm("Pergunta secreta", "Ajuda a recuperar a senha se você esquecer.", true)
            return
        end if
        m.fase = "novo1"
        m.pinNovo = ""
        m.msgTxt = "As senhas não conferem. Tente de novo."
        mostrarTeclado("Criar nova senha", "Digite 4 números.", false)
    end if
end sub

sub apertar(id as String)
    if id = "Apagar" then
        if Len(m.digitos) > 0 then m.digitos = Left(m.digitos, Len(m.digitos) - 1)
        pintarPontos()
        mensagem("")
    else if id = "Cancelar" then
        terminar(false)
    else
        digitar(id)
    end if
end sub

sub iniciarRecuperacao()
    m.fase = "rec"
    m.msgTxt = ""
    mostrarForm("Recuperar senha", "Responda a pergunta secreta.", false)
end sub

sub abrirTecladoResposta()
    uiTeclado("Sua resposta", "Digite e confirme.", m.resp, false, respostaOk)
end sub

sub respostaOk(texto as String)
    m.resp = texto
    if texto = "" then
        m.respTxt.text = tx("Sua resposta")
        m.respTxt.color = cSuave()
    else
        m.respTxt.text = texto
        m.respTxt.color = cTexto()
    end if
    pintarFoco()
end sub

sub confirmarForm()
    if Len(normalizarResposta(m.resp)) < 2 then
        mensagem("Digite a resposta.")
        return
    end if
    if m.fase = "perg" then
        e = parentalLer()
        e.pin = hashParental(m.pinNovo)
        e.perg = m.qIdx
        e.resp = hashParental(normalizarResposta(m.resp))
        parentalGravar(e)
        terminar(true)
    else if m.fase = "rec" then
        if respostaConfere(m.resp) then
            m.fase = "novo1"
            m.msgTxt = ""
            mostrarTeclado("Criar nova senha", "Digite 4 números.", false)
        else
            mensagem("Resposta incorreta.")
        end if
    end if
end sub

sub trocarPergunta(passo as Integer)
    n = perguntasSecretas().Count()
    m.qIdx = (m.qIdx + passo + n) mod n
    m.pergTxt.text = Chr(9664) + "  " + perguntasSecretas()[m.qIdx] + "  " + Chr(9654)
end sub

sub terminar(ok as Boolean)
    if m.fim then return
    m.fim = true
    m.top.resultado = { ok: ok }
end sub

function onKeyEvent(tecla as String, pressionou as Boolean) as Boolean
    if not pressionou then return true
    if tecla = "back" then
        terminar(false)
        return true
    end if
    if m.zona = "form" then
        f = m.formItens[m.formIdx]
        if tecla = "up" then
            if m.formIdx > 0 then m.formIdx = m.formIdx - 1
            pintarFoco()
        else if tecla = "down" then
            if m.formIdx < 1 then
                m.formIdx = m.formIdx + 1
            else if m.formIdx = 1 then
                m.formIdx = 2
            end if
            pintarFoco()
        else if tecla = "left" then
            if f.tipo = "pergunta" and m.fase = "perg" then
                trocarPergunta(-1)
            else if m.formIdx = 3 then
                m.formIdx = 2
                pintarFoco()
            end if
        else if tecla = "right" then
            if f.tipo = "pergunta" and m.fase = "perg" then
                trocarPergunta(1)
            else if m.formIdx = 2 then
                m.formIdx = 3
                pintarFoco()
            end if
        else if tecla = "OK" then
            if f.tipo = "pergunta" and m.fase = "perg" then
                trocarPergunta(1)
            else if f.tipo = "texto" then
                abrirTecladoResposta()
            else if f.tipo = "ok" then
                confirmarForm()
            else if f.tipo = "cancelar" then
                terminar(false)
            end if
        end if
        return true
    end if
    if m.zona = "esqueci" then
        if tecla = "up" then
            m.zona = "teclado"
            m.lin = 3
            m.col = 1
            pintarFoco()
        else if tecla = "OK" then
            iniciarRecuperacao()
        end if
        return true
    end if
    if tecla = "left" then
        if m.col > 0 then m.col = m.col - 1
    else if tecla = "right" then
        if m.col < 2 then m.col = m.col + 1
    else if tecla = "up" then
        if m.lin > 0 then m.lin = m.lin - 1
    else if tecla = "down" then
        if m.lin = 3 and m.esq <> invalid then
            m.zona = "esqueci"
        else if m.lin < 3 then
            m.lin = m.lin + 1
        end if
    else if tecla = "OK" then
        apertar(m.teclasPin[m.lin * 3 + m.col].id)
        return true
    else if Len(tecla) = 5 and Left(tecla, 4) = "Lit_" then
        d = Right(tecla, 1)
        if d >= "0" and d <= "9" then digitar(d)
        return true
    else if LCase(tecla) = "backspace" then
        apertar("Apagar")
        return true
    end if
    pintarFoco()
    return true
end function
