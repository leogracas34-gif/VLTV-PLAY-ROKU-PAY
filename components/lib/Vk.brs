' VLTV Play - Roku | Ferramentas de desenho da interface. Reproduzem o CSS do app da LG (cores, cantos, brilho de foco).
' Tudo é desenhado com imagens geradas (pkg:/images/ui) tingidas por blendColor; nenhum componente padrão da Roku.

' ── Cores (iguais às variáveis do style.css da LG) ──────────────────
function cFundoPainel() as String
    return "0x141416FF"
end function
function cPainel2() as String
    return "0x1F1F23FF"
end function
function cBorda() as String
    return "0x2E2E34FF"
end function
function cTexto() as String
    return "0xF5F5F7FF"
end function
function cSuave() as String
    return "0x9C9CA8FF"
end function
function cDest() as String
    return "0xE50914FF"
end function
function cClaro() as String
    return "0xFF4B55FF"
end function
function cOk() as String
    return "0x5BE3A4FF"
end function
function cErro() as String
    return "0xFF8A92FF"
end function
function cBranco() as String
    return "0xFFFFFFFF"
end function
function cOuro() as String
    return "0xFFC94DFF"
end function
function cNota() as String
    return "0xFFD700FF"
end function

' ── Fontes e textos ─────────────────────────────────────────────────
function vkFonte(tam as Integer, negrito as Boolean) as Object
    if m.vkF = invalid then m.vkF = {}
    k = Str(tam).Trim()
    if negrito then k = k + "b" else k = k + "r"
    if m.vkF[k] = invalid then
        f = CreateObject("roSGNode", "Font")
        if negrito then
            f.uri = "pkg:/images/LiberationSans-Bold.ttf"
        else
            f.uri = "pkg:/images/LiberationSans-Regular.ttf"
        end if
        f.size = tam
        m.vkF[k] = f
    end if
    return m.vkF[k]
end function

' Texto de uma linha (corta com "..." se não couber). alinh: "left" | "center" | "right"
function vkTxt(pai as Object, x as Integer, y as Integer, w as Integer, h as Integer, texto as String, tam as Integer, negrito as Boolean, cor as String, alinh as String) as Object
    return uiNo(pai, "Label", { translation: [x, y], width: w, height: h, text: texto, font: vkFonte(tam, negrito), color: cor, vertAlign: "center", horizAlign: alinh, ellipsisText: "..." })
end function

' Texto em várias linhas.
function vkTxtM(pai as Object, x as Integer, y as Integer, w as Integer, h as Integer, texto as String, tam as Integer, negrito as Boolean, cor as String, maxLin as Integer, alinh as String) as Object
    return uiNo(pai, "Label", { translation: [x, y], width: w, height: h, text: texto, font: vkFonte(tam, negrito), color: cor, vertAlign: "top", horizAlign: alinh, wrap: true, maxLines: maxLin, lineSpacing: 0, ellipsisText: "..." })
end function

' Imagem de pkg:/images/ui (sem extensão). modo: "scaleToFit" | "scaleToZoom" | "scaleToFill"
function vkImg(pai as Object, x as Integer, y as Integer, w as Integer, h as Integer, nome as String, cor as String) as Object
    n = uiNo(pai, "Poster", { translation: [x, y], width: w, height: h, uri: "pkg:/images/ui/" + nome + ".png", loadDisplayMode: "scaleToFit" })
    if cor <> "" then n.blendColor = cor
    return n
end function

' Forma 9-patch (cantos arredondados que esticam)
function vkNine(pai as Object, x as Integer, y as Integer, w as Integer, h as Integer, nome as String) as Object
    return uiNo(pai, "Poster", { translation: [x, y], width: w, height: h, uri: "pkg:/images/ui/" + nome + ".9.png", blendColor: "0xFFFFFFFF" })
end function

function vkRet(pai as Object, x as Integer, y as Integer, w as Integer, h as Integer, cor as String) as Object
    return uiNo(pai, "Rectangle", { translation: [x, y], width: w, height: h, color: cor })
end function

' Fundo do app (brilhos roxo/vermelho, listras, vinheta) – o mesmo da Home.
sub vkFundo(pai as Object)
    uiNo(pai, "Poster", { translation: [0, 0], width: 1920, height: 1080, uri: "pkg:/images/home_fundo.jpg", loadDisplayMode: "scaleToFill" })
end sub

' ── Caixa arredondada com borda e brilho de foco ───────────────────
' raio e espessura da borda em px; gl = espessura do brilho de foco (4, 6 ou 8).
function vkCaixa(pai as Object, x as Integer, y as Integer, w as Integer, h as Integer, raio as Integer, bw as Integer, gl as Integer) as Object
    g = uiNo(pai, "Group", { translation: [x, y] })
    c = { grupo: g, w: w, h: h, r: raio, bw: bw, gl: gl }
    c.glow = vkNine(g, -gl, -gl, w + 2 * gl, h + 2 * gl, "g" + Str(raio).Trim() + "_" + Str(gl).Trim())
    c.glow.blendColor = cDest()
    c.glow.opacity = 0.5
    c.glow.visible = false
    c.borda = vkNine(g, 0, 0, w, h, "f" + Str(raio).Trim())
    ri = raio - bw
    if ri < 1 then ri = 1
    c.fundo = vkNine(g, bw, bw, w - 2 * bw, h - 2 * bw, "f" + Str(ri).Trim())
    return c
end function

' borda/fundo: cor "0xRRGGBBAA" ou "" (sem). Borda "" = igual ao fundo (CSS: borda transparente sobre o fundo).
sub vkPintar(c as Object, borda as String, fundo as String, brilho as Boolean)
    c.glow.visible = brilho
    b = borda
    if b = "" then b = fundo
    c.borda.visible = (b <> "")
    if b <> "" then c.borda.blendColor = b
    c.fundo.visible = (fundo <> "")
    if fundo <> "" then c.fundo.blendColor = fundo
end sub

sub vkMover(c as Object, x as Integer, y as Integer)
    c.grupo.translation = [x, y]
end sub

' Painel das telas (fundo escuro, borda 3px, cantos 18). ativo = borda vermelha.
function vkPainel(pai as Object, x as Integer, y as Integer, w as Integer, h as Integer, titulo as String, ativo as Boolean) as Object
    p = vkCaixa(pai, x, y, w, h, 18, 3, 6)
    cor = cBorda()
    if ativo then cor = cClaro()
    vkPintar(p, cor, cFundoPainel(), false)
    p.titulo = vkTxt(p.grupo, 32, 27, w - 64, 56, titulo, 32, true, cSuave(), "left")
    return p
end function

sub vkPainelAtivo(p as Object, ativo as Boolean)
    cor = cBorda()
    if ativo then cor = cClaro()
    p.borda.blendColor = cor
end sub

' Botão retangular dos formulários (Entrar, abas...). Devolve { caixa, txt }.
function vkBotao(pai as Object, x as Integer, y as Integer, w as Integer, h as Integer, texto as String, tam as Integer) as Object
    b = {}
    b.caixa = vkCaixa(pai, x, y, w, h, 14, 3, 6)
    b.txt = vkTxt(b.caixa.grupo, 0, 0, w, h, texto, tam, true, cBranco(), "center")
    b.w = w
    b.h = h
    return b
end function

' ── Lista vertical (categorias, canais, configurações, listas) ──────
' opc: { icone: true|false } reserva 64x48 de imagem na esquerda.
function vkLista(pai as Object, x as Integer, y as Integer, w as Integer, h as Integer, alt as Integer, espaco as Integer, tam as Integer) as Object
    l = { w: w, alt: alt, passo: alt + espaco, tam: tam, itens: [], idx: 0, topo: 0, ativo: true, linhas: [], estrelaFoco: false, col: 0 }
    l.nVis = Int(h / l.passo)
    if l.nVis < 1 then l.nVis = 1
    l.grupo = uiNo(pai, "Group", { translation: [x, y], clippingRect: [0, 0, w, h] })
    for i = 0 to l.nVis - 1
        l.linhas.Push(vkLinhaNova(l, i))
    end for
    return l
end function

function vkLinhaNova(l as Object, i as Integer) as Object
    w = l.w
    alt = l.alt
    r = {}
    r.grupo = uiNo(l.grupo, "Group", { translation: [0, i * l.passo], visible: false })
    r.caixa = vkCaixa(r.grupo, 0, 0, w, alt, 12, 3, 4)
    r.caixa.grupo.visible = false
    r.marca = vkRet(r.grupo, 3, 14, 6, alt - 28, cOk())
    r.marca.visible = false
    r.icone = uiNo(r.grupo, "Poster", { translation: [24, Int((alt - 48) / 2)], width: 64, height: 48, loadDisplayMode: "scaleToFit", visible: false })
    r.nome = vkTxt(r.grupo, 24, 0, w - 48, alt, "", l.tam, false, cTexto(), "left")
    r.subt = vkTxt(r.grupo, 24, 0, w - 48, 26, "", 21, false, cSuave(), "left")
    r.subt.visible = false
    r.estrelaFundo = vkNine(r.grupo, w - 63, Int((alt - 44) / 2), 44, 44, "f22")
    r.estrelaFundo.blendColor = cBranco()
    r.estrelaFundo.visible = false
    r.estrela = vkImg(r.grupo, w - 58, Int((alt - 34) / 2), 34, 34, "i_estrela_vazia", cBranco())
    r.estrela.visible = false
    r.cad = vkImg(r.grupo, w - 58, Int((alt - 30) / 2), 30, 30, "i_cadeado", cBranco())
    r.cad.opacity = 0.85
    r.cad.visible = false
    r.badge = vkCaixa(r.grupo, 0, Int((alt - 40) / 2), 120, 40, 20, 2, 4)
    r.badge.grupo.visible = false
    r.badgeTxt = vkTxt(r.badge.grupo, 0, 0, 120, 40, "", 21, true, cOk(), "center")
    r.rmv = vkCaixa(r.grupo, 0, Int((alt - 46) / 2), 150, 46, 12, 2, 4)
    r.rmv.grupo.visible = false
    r.remTxt = vkTxt(r.rmv.grupo, 0, 0, 150, 46, "", 22, false, cSuave(), "center")
    return r
end function

' Escreve o conteúdo de uma linha. it: { nome, sub, icone, iconeCor, iconeW, iconeH, estrela(0|1|2), cad, marca, neg, cor,
'   msg, badge, rem, remTxt }
sub vkLinhaPreencher(l as Object, r as Object, it as Object, sel as Boolean)
    w = l.w
    alt = l.alt
    ativo = l.ativo
    r.grupo.visible = true
    if sel then
        if ativo then
            vkPintar(r.caixa, cBranco(), cDest(), false)
        else
            vkPintar(r.caixa, cBorda(), cPainel2(), false)
        end if
        r.caixa.grupo.visible = true
    else
        r.caixa.grupo.visible = false
    end if
    ' cor de fundo da linha (para botões só com contorno)
    fundoLinha = cFundoPainel()
    if sel and ativo then fundoLinha = cDest()
    if sel and not ativo then fundoLinha = cPainel2()
    ' cor do texto
    cor = cTexto()
    if sv(it.cor) <> "" then cor = it.cor
    if sel and ativo then cor = cBranco()
    if it.msg = true then
        r.nome.wrap = true
        r.nome.vertAlign = "top"
        r.nome.translation = [16, 24]
        r.nome.width = w - 32
        r.nome.height = alt * 3
        r.nome.maxLines = 6
        r.nome.text = sv(it.nome)
        r.nome.color = cSuave()
        r.nome.font = vkFonte(27, false)
        r.marca.visible = false
        r.icone.visible = false
        r.estrela.visible = false
        r.estrelaFundo.visible = false
        r.cad.visible = false
        r.subt.visible = false
        r.badge.grupo.visible = false
        r.rmv.grupo.visible = false
        return
    end if
    r.nome.wrap = false
    r.nome.vertAlign = "center"
    r.nome.maxLines = 1
    ' marca colorida na esquerda (tocando / carregada / aplicada)
    marca = sv(it.marca)
    r.marca.visible = (marca <> "")
    if marca = "ok" then r.marca.color = cOk()
    if marca = "claro" then r.marca.color = cClaro()
    ' imagem / ícone
    x0 = 24
    if sv(it.icone) <> "" then
        iw = 64
        ih = 48
        if it.iconeW <> invalid then iw = it.iconeW
        if it.iconeH <> invalid then ih = it.iconeH
        r.icone.width = iw
        r.icone.height = ih
        r.icone.translation = [x0, Int((alt - ih) / 2)]
        r.icone.uri = it.icone
        r.icone.blendColor = "0xFFFFFFFF"
        if sv(it.iconeCor) <> "" then r.icone.blendColor = it.iconeCor
        r.icone.visible = true
        x0 = x0 + iw + 16
    else
        r.icone.visible = false
        r.icone.uri = ""
    end if
    ' lado direito
    dir = 16
    r.estrelaFundo.visible = false
    r.estrela.visible = false
    if it.estrela <> invalid then
        if it.estrela > 0 then
            foco = (sel and l.estrelaFoco = true)
            r.estrelaFundo.visible = foco
            r.estrela.visible = true
            if it.estrela = 2 then
                r.estrela.uri = "pkg:/images/ui/i_estrela.png"
                if foco then r.estrela.blendColor = "0xF5A800FF" else r.estrela.blendColor = cOuro()
            else
                r.estrela.uri = "pkg:/images/ui/i_estrela_vazia.png"
                if foco then r.estrela.blendColor = cFundoPainel() else r.estrela.blendColor = "0xFFFFFF8C"
            end if
            dir = dir + 54
        end if
    end if
    r.cad.visible = (it.cad = true)
    if it.cad = true then
        r.cad.translation = [w - dir - 36, Int((alt - 30) / 2)]
        dir = dir + 42
    end if
    r.badge.grupo.visible = false
    if sv(it.badge) <> "" then
        bw = 40 + Len(sv(it.badge)) * 13
        r.badge.grupo.translation = [w - dir - bw, Int((alt - 40) / 2)]
        r.badge.borda.width = bw
        r.badge.fundo.width = bw - 4
        r.badge.glow.visible = false
        r.badgeTxt.width = bw
        r.badgeTxt.text = it.badge
        c = cOk()
        if sel and ativo then c = cBranco()
        vkPintar(r.badge, c, fundoLinha, false)
        r.badgeTxt.color = c
        r.badge.grupo.visible = true
        dir = dir + bw + 16
    end if
    r.rmv.grupo.visible = false
    if sv(it.rmv) <> "" then
        rw = 40 + Len(sv(it.rmv)) * 13
        r.rmv.grupo.translation = [w - dir - rw, Int((alt - 46) / 2)]
        r.rmv.borda.width = rw
        r.rmv.fundo.width = rw - 4
        r.remTxt.width = rw
        r.remTxt.text = it.rmv
        if sel and l.col = 1 then
            vkPintar(r.rmv, cBranco(), "0x000000FF", false)
            r.remTxt.color = cBranco()
        else
            vkPintar(r.rmv, cBorda(), fundoLinha, false)
            r.remTxt.color = cSuave()
            if sel and ativo then r.remTxt.color = cBranco()
        end if
        r.rmv.grupo.visible = true
        dir = dir + rw + 20
    end if
    ' textos
    tw = w - x0 - dir
    if tw < 40 then tw = 40
    neg = (it.neg = true)
    r.nome.font = vkFonte(l.tam, neg)
    r.nome.color = cor
    r.nome.text = sv(it.nome)
    r.nome.width = tw
    r.nome.horizAlign = "left"
    if sv(it.subt) <> "" then
        r.nome.translation = [x0, 10]
        r.nome.height = 34
        r.subt.translation = [x0, 46]
        r.subt.width = tw
        r.subt.height = 26
        r.subt.text = it.subt
        if sel and ativo then r.subt.color = "0xFFFFFFCC" else r.subt.color = cSuave()
        r.subt.visible = true
    else
        r.nome.translation = [x0, 0]
        r.nome.height = alt
        r.subt.visible = false
    end if
end sub

' Redesenha as linhas visíveis (conteúdo + seleção).
sub vkListaDesenhar(l as Object)
    n = l.itens.Count()
    for i = 0 to l.nVis - 1
        j = l.topo + i
        r = l.linhas[i]
        if j < n then
            vkLinhaPreencher(l, r, l.itens[j], (j = l.idx and l.semSel <> true))
        else
            r.grupo.visible = false
        end if
    end for
end sub

sub vkListaItens(l as Object, itens as Object)
    l.itens = itens
    if l.idx >= itens.Count() then l.idx = itens.Count() - 1
    if l.idx < 0 then l.idx = 0
    l.topo = 0
    vkListaAjustar(l)
    vkListaDesenhar(l)
end sub

sub vkListaAjustar(l as Object)
    if l.idx < l.topo then l.topo = l.idx
    if l.idx > l.topo + l.nVis - 1 then l.topo = l.idx - l.nVis + 1
    mx = l.itens.Count() - l.nVis
    if mx < 0 then mx = 0
    if l.topo > mx then l.topo = mx
    if l.topo < 0 then l.topo = 0
end sub

' Move o destaque para o índice i (limitado ao início/fim).
sub vkListaIr(l as Object, i as Integer)
    n = l.itens.Count()
    if n = 0 then return
    if i < 0 then i = 0
    if i > n - 1 then i = n - 1
    l.idx = i
    vkListaAjustar(l)
    vkListaDesenhar(l)
end sub

function vkListaItem(l as Object) as Dynamic
    if l.idx < 0 or l.idx >= l.itens.Count() then return invalid
    return l.itens[l.idx]
end function

' ── Grade de capas (Filmes, Séries, sugestões) ─────────────────────
' Cada célula: capa 206x296 (borda 4, cantos 12) + nome em 2 linhas.
function vkGrade(pai as Object, x as Integer, y as Integer, w as Integer, h as Integer, colunas as Integer, cw as Integer, ch as Integer, nomeH as Integer, espX as Integer, espY as Integer, tamNome as Integer) as Object
    g = { colunas: colunas, cw: cw, ch: ch, nomeH: nomeH, passoX: cw + espX, passoY: ch + nomeH + espY, itens: [], idx: 0, topo: 0, ativo: true, celulas: [], tamNome: tamNome, fundoMascara: cFundoPainel() }
    g.nLin = Int(h / g.passoY) + 1
    if g.nLin < 2 then g.nLin = 2
    g.grupo = uiNo(pai, "Group", { translation: [x, y], clippingRect: [0, 0, w, h] })
    for i = 0 to g.nLin * colunas - 1
        g.celulas.Push(vkCelulaNova(g, i))
    end for
    return g
end function

function vkCelulaNova(g as Object, i as Integer) as Object
    col = i mod g.colunas
    lin = Int(i / g.colunas)
    c = {}
    c.grupo = uiNo(g.grupo, "Group", { translation: [col * g.passoX, lin * g.passoY], visible: false })
    c.caixa = vkCaixa(c.grupo, 0, 0, g.cw, g.ch, 12, 4, 4)
    c.inicial = vkTxt(c.grupo, 0, 0, g.cw, g.ch, "", 72, true, cSuave(), "center")
    c.capa = uiNo(c.grupo, "Poster", { translation: [4, 4], width: g.cw - 8, height: g.ch - 8, loadDisplayMode: "scaleToZoom" })
    c.mascara = vkNine(c.grupo, 4, 4, g.cw - 8, g.ch - 8, "m8")
    c.nota = vkTxt(c.grupo, 14, 12, 90, 28, "", 22, true, cNota(), "left")
    c.prog = vkRet(c.grupo, 4, g.ch - 12, 0, 8, cClaro())
    c.prog.visible = false
    c.nome = vkTxtM(c.grupo, 2, g.ch + 6, g.cw - 4, g.nomeH - 4, "", g.tamNome, false, cTexto(), 2, "left")
    return c
end function

sub vkCelulaPreencher(g as Object, c as Object, it as Object, sel as Boolean)
    c.grupo.visible = true
    c.nome.text = sv(it.nome)
    capa = sv(it.capa)
    if c.uri <> capa then
        c.capa.uri = capa
        c.uri = capa
    end if
    ini = ""
    if Len(sv(it.nome)) > 0 then ini = UCase(Left(sv(it.nome), 1))
    c.inicial.text = ini
    c.inicial.visible = (capa = "")
    if sv(it.nota) <> "" then
        c.nota.text = "★ " + sv(it.nota)
    else
        c.nota.text = ""
    end if
    c.nota.visible = false
    if it.pct <> invalid then
        if it.pct > 0 then
            c.prog.width = Int((g.cw - 8) * it.pct / 100)
            c.prog.visible = true
        else
            c.prog.visible = false
        end if
    else
        c.prog.visible = false
    end if
    if sel and g.ativo then
        vkPintar(c.caixa, cBranco(), cPainel2(), true)
        c.caixa.glow.blendColor = cClaro()
        c.caixa.glow.opacity = 0.55
        c.mascara.blendColor = cBranco()
        c.nome.color = cBranco()
        c.nome.font = vkFonte(g.tamNome, true)
    else
        if sel then
            vkPintar(c.caixa, cBorda(), cPainel2(), false)
            c.mascara.blendColor = cBorda()
        else
            vkPintar(c.caixa, "", cPainel2(), false)
            c.mascara.blendColor = cPainel2()
        end if
        c.nome.color = cTexto()
        c.nome.font = vkFonte(g.tamNome, false)
    end if
end sub

sub vkGradeDesenhar(g as Object)
    n = g.itens.Count()
    for i = 0 to g.celulas.Count() - 1
        j = g.topo * g.colunas + i
        c = g.celulas[i]
        if j < n then
            vkCelulaPreencher(g, c, g.itens[j], (j = g.idx and g.semSel <> true))
        else
            c.grupo.visible = false
        end if
    end for
end sub

sub vkGradeItens(g as Object, itens as Object)
    g.itens = itens
    g.idx = 0
    g.topo = 0
    vkGradeDesenhar(g)
end sub

sub vkGradeIr(g as Object, i as Integer)
    n = g.itens.Count()
    if n = 0 then return
    if i < 0 then i = 0
    if i > n - 1 then i = n - 1
    g.idx = i
    lin = Int(i / g.colunas)
    if lin < g.topo then g.topo = lin
    if lin > g.topo + g.nLin - 2 then g.topo = lin - (g.nLin - 2)
    if g.topo < 0 then g.topo = 0
    vkGradeDesenhar(g)
end sub

' Navegação da grade. Devolve true se mexeu.
function vkGradeTecla(g as Object, tecla as String) as Boolean
    n = g.itens.Count()
    if n = 0 then return false
    i = g.idx
    col = i mod g.colunas
    if tecla = "left" then
        if col = 0 then return false
        vkGradeIr(g, i - 1)
        return true
    else if tecla = "right" then
        if i < n - 1 and col < g.colunas - 1 then vkGradeIr(g, i + 1)
        return true
    else if tecla = "up" then
        if i < g.colunas then return false
        vkGradeIr(g, i - g.colunas)
        return true
    else if tecla = "down" then
        if i + g.colunas < n then
            vkGradeIr(g, i + g.colunas)
        else if Int(i / g.colunas) < Int((n - 1) / g.colunas) then
            vkGradeIr(g, n - 1)
        end if
        return true
    end if
    return false
end function

' Tecla "OK" do Roku vem como "OK"; "fastforward" e "rewind" pulam páginas nas listas longas.
function vkEhSeta(t as String) as Boolean
    return t = "up" or t = "down" or t = "left" or t = "right"
end function

' Largura de um texto em px (mede com um Label escondido; se não conseguir, estima).
function vkMedir(texto as String, tam as Integer, negrito as Boolean) as Integer
    if m.vkMed = invalid then
        m.vkMed = CreateObject("roSGNode", "Label")
        m.vkMed.visible = false
        m.top.appendChild(m.vkMed)
    end if
    m.vkMed.font = vkFonte(tam, negrito)
    m.vkMed.text = texto
    w = Int(m.vkMed.boundingRect().width)
    f = 0.5
    if negrito then f = 0.56
    est = Int(Len(texto) * tam * f)
    if w < 4 and Len(texto) > 0 then return est
    return w
end function
