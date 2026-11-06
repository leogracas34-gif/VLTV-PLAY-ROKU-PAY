' VLTV Play - Roku | Detalhe do filme/série igual ao da LG: fundo com degradê, título, meta, ASSISTIR (pílula branca),
' REINICIAR / MINHA LISTA, sinopse e abas EPISÓDIOS / SUGESTÕES / DETALHES. A página sobe ao entrar nas abas.

sub iniciar()
    carregarI18n()
    a = m.top.args
    m.tipo = sv(a.tipo)
    m.id = sv(a.id)
    m.nomeBruto = sv(a.nome)
    m.capaUrl = sv(a.capa)
    m.ext = sv(a.ext)
    m.cat = sv(a.cat)
    m.temporadas = []
    m.tempIdx = 0
    m.titulo = limparTitulo(m.nomeBruto)
    m.info = {}
    m.sinopseTxt = ""
    m.plotPainel = ""
    m.generoTxt = ""
    m.anoTxt = ""
    m.durTxt = ""
    m.notaTxt = ""
    m.logoUrl = ""
    m.elenco = ""
    m.direcao = ""
    m.lancamento = ""
    m.falha = false
    m.adulto = false
    m.alvo = invalid
    m.sugs = []
    m.zona = "play"
    m.secIdx = 0
    m.abaIdx = 0
    m.popup = false
    m.tmdbEps = invalid
    m.eps = []
    m.epSel = 0
    m.epTopo = 0

    ' fundo
    m.fundo = uiNo(m.top, "Poster", { translation: [0, 0], width: 1920, height: 1080, uri: m.capaUrl, loadDisplayMode: "scaleToZoom", opacity: 0.35 })
    uiNo(m.top, "Poster", { translation: [0, 0], width: 1920, height: 1080, uri: "pkg:/images/ui/grad_det.png", loadDisplayMode: "scaleToFill" })
    m.rolado = vkRet(m.top, 0, 0, 1920, 1080, "0x000000ED")
    m.rolado.visible = false
    m.pagina = uiNo(m.top, "Group", { translation: [0, 0] })
    p = m.pagina

    ' título (logo ou texto)
    m.logo = uiNo(p, "Poster", { translation: [550, 95], width: 820, height: 140, loadDisplayMode: "scaleToFit", visible: false })
    m.tit = uiNo(p, "Label", { translation: [300, 90], width: 1320, height: 150, text: m.titulo, font: vkFonte(68, true), color: cBranco(), horizAlign: "center", vertAlign: "center", wrap: true, maxLines: 2, lineSpacing: 0 })
    ' meta
    m.metaL = []
    for i = 0 to 2
        m.metaL.Push(uiNo(p, "Label", { translation: [0, 0], height: 44, font: vkFonte(30, false), color: "0xCCCCCCFF", vertAlign: "center" }))
    end for
    m.tagBg = vkNine(p, 0, 0, 60, 36, "f8")
    m.tagBg.blendColor = "0xFFFFFF33"
    m.tagTxt = uiNo(p, "Label", { translation: [0, 0], width: 60, height: 36, font: vkFonte(24, true), color: cBranco(), horizAlign: "center", vertAlign: "center", text: "HD" })
    m.genero = vkTxt(p, 300, 0, 1320, 34, "", 28, false, "0xCCCCCCFF", "center")
    ' progresso
    m.pgBg = vkRet(p, 580, 0, 0, 8, "0xFFFFFF47")
    m.pgFill = vkRet(p, 580, 0, 0, 8, cClaro())
    m.pgTxt = vkTxt(p, 0, 0, 220, 32, "", 24, false, "0xCCCCCCFF", "left")
    ' ASSISTIR
    m.play = vkCaixa(p, 680, 0, 560, 92, 46, 4, 8)
    m.playTxt = uiNo(m.play.grupo, "Label", { translation: [0, 0], width: 560, height: 92, font: vkFonte(36, true), color: "0x000000FF", horizAlign: "center", vertAlign: "center", text: tx("ASSISTIR") })
    m.playIco = vkImg(m.play.grupo, 0, 29, 34, 34, "i_play", "0x000000FF")
    ' ações
    m.sec = []
    m.sec.Push(acaoNova(p, "i_reiniciar", "REINICIAR"))
    m.sec.Push(acaoNova(p, "i_estrela_vazia", "MINHA LISTA"))
    m.sinopse = vkTxtM(p, 410, 0, 1100, 117, "", 28, false, cBranco(), 3, "center")
    ' abas
    m.abaIds = ["sug", "det"]
    m.abaNomes = ["SUGESTÕES", "DETALHES"]
    if m.tipo = "series" then
        m.abaIds = ["eps", "sug", "det"]
        m.abaNomes = ["EPISÓDIOS", "SUGESTÕES", "DETALHES"]
    end if
    m.abaLinha = vkRet(p, 300, 0, 1320, 2, "0xFFFFFF33")
    m.abasUi = []
    for i = 0 to m.abaIds.Count() - 1
        b = {}
        b.fundo = vkNine(p, 0, 0, 100, 70, "f12")
        b.fundo.blendColor = cDest()
        b.fundo.visible = false
        b.txt = uiNo(p, "Label", { translation: [0, 0], height: 66, font: vkFonte(30, true), color: "0xFFFFFF8C", horizAlign: "center", vertAlign: "center", text: tx(m.abaNomes[i]) })
        b.sub = vkRet(p, 0, 0, 100, 5, cBranco())
        b.sub.visible = false
        m.abasUi.Push(b)
    end for

    ' seção episódios
    m.temp = vkCaixa(p, 304, 0, 300, 68, 14, 3, 6)
    m.tempTxt = uiNo(m.temp.grupo, "Label", { translation: [34, 0], width: 280, height: 68, font: vkFonte(30, true), color: cBranco(), vertAlign: "center", text: "" })
    m.tempSeta = uiNo(m.temp.grupo, "Poster", { translation: [0, 28], width: 18, height: 12, uri: "pkg:/images/ui/i_seta.png", loadDisplayMode: "scaleToFit", visible: false })
    m.epJanela = uiNo(p, "Group", { translation: [300, 0], clippingRect: [0, 0, 1320, 720] })
    m.epCel = []
    for i = 0 to 11
        m.epCel.Push(epCelulaNova(m.epJanela, i))
    end for
    m.epMsg = vkTxtM(p, 308, 0, 1300, 120, "", 30, false, cSuave(), 3, "left")
    ' sugestões
    m.sugGrade = vkGrade(p, 304, 0, 1320, 780, 6, 208, 296, 68, 10, 12, 24)
    m.sugGrade.grupo.visible = false
    m.sugMsg = vkTxtM(p, 308, 0, 1300, 120, "", 30, false, cSuave(), 3, "left")
    ' detalhes
    m.detTit = vkTxtM(p, 410, 0, 1100, 60, "", 40, true, cBranco(), 1, "left")
    m.detSin = vkTxtM(p, 410, 0, 1100, 300, "", 28, false, "0xCFCFD8FF", 7, "left")
    m.detLin = []
    for i = 0 to 4
        r = vkTxt(p, 410, 0, 260, 38, "", 27, true, cBranco(), "left")
        v = vkTxtM(p, 410, 0, 800, 76, "", 27, false, "0xCFCFD8FF", 2, "left")
        m.detLin.Push({ r: r, v: v })
    end for

    ' esmaece o topo quando a página sobe
    m.fade = uiNo(m.top, "Poster", { translation: [0, 0], width: 1920, height: 150, uri: "pkg:/images/ui/grad_fadetopo.png", loadDisplayMode: "scaleToFill", visible: false })

    ' janela da temporada
    m.pop = uiNo(m.top, "Group", { visible: false })
    vkRet(m.pop, 0, 0, 1920, 1080, "0x000000B3")
    m.popCx = vkCaixa(m.pop, 650, 120, 620, 840, 20, 3, 6)
    vkPintar(m.popCx, cClaro(), cFundoPainel(), false)
    vkTxt(m.popCx.grupo, 36, 28, 540, 50, tx("Temporadas"), 32, false, cSuave(), "left")
    m.popLista = vkLista(m.popCx.grupo, 24, 96, 572, 720, 76, 4, 32)

    m.msgCarregando = true
    relayout()
    atualizarBotoes()
    m.top.setFocus(true)

    if m.tipo = "series" then
        chamar("ApiTask", "info_serie", { id: m.id }, "aoInfoSerie")
    else
        chamar("ApiTask", "info_filme", { id: m.id }, "aoInfoFilme")
    end if
    chamar("TmdbTask", "detalhe", { tipo: m.tipo, id: m.id, nome: m.nomeBruto }, "aoTmdb")
    ' As sugestões (lê a categoria inteira do arquivo) só são pedidas depois que as informações chegam,
    ' para não disputar o processador com o que o usuário está esperando ver.
    m.sugPedido = false
end sub

sub pedirSugestoes()
    if m.sugPedido = true then return
    m.sugPedido = true
    chamar("ApiTask", "itens", { tipo: m.tipo, cat: m.cat, modo: "cache" }, "aoSugestoes")
end sub

function acaoNova(p as Object, icone as String, rotulo as String) as Object
    a = {}
    a.caixa = vkCaixa(p, 0, 0, 200, 116, 18, 3, 6)
    a.ico = vkImg(a.caixa.grupo, 79, 20, 42, 42, icone, cBranco())
    a.txt = vkTxt(a.caixa.grupo, 0, 70, 200, 30, tx(rotulo), 22, true, cBranco(), "center")
    a.id = icone
    return a
end function

function epCelulaNova(pai as Object, i as Integer) as Object
    col = i mod 4
    lin = Int(i / 4)
    c = {}
    c.grupo = uiNo(pai, "Group", { translation: [col * 335, lin * 308], visible: false })
    c.caixa = vkCaixa(c.grupo, 0, 0, 315, 284, 16, 3, 6)
    c.thumb = vkRet(c.grupo, 3, 3, 309, 174, cPainel2())
    c.ini = vkTxt(c.grupo, 3, 3, 309, 174, "", 56, false, cSuave(), "center")
    c.capa = uiNo(c.grupo, "Poster", { translation: [3, 3], width: 309, height: 174, loadDisplayMode: "scaleToZoom" })
    c.numBg = vkNine(c.grupo, 13, 13, 46, 40, "f10")
    c.numBg.blendColor = "0x000000B8"
    c.num = vkTxt(c.grupo, 13, 13, 46, 40, "", 26, true, cBranco(), "center")
    c.pgBg = vkRet(c.grupo, 3, 169, 309, 8, "0x000000A6")
    c.pgFill = vkRet(c.grupo, 3, 169, 0, 8, cClaro())
    c.tit = vkTxtM(c.grupo, 15, 187, 285, 62, "", 26, true, cTexto(), 2, "left")
    c.dur = vkTxt(c.grupo, 15, 251, 285, 28, "", 22, false, cClaro(), "left")
    c.uri = ""
    return c
end function

sub retomar()
    progressoInvalidar()   ' voltou do player: o progresso mudou
    atualizarBotoes()
    desenharEpisodios()
    m.top.setFocus(true)
end sub

sub focar()
    m.top.setFocus(true)
end sub

sub encerrar()
end sub

' ── Posição de tudo (muda conforme o que existe) ────────────────────
sub relayout()
    ' logo ou nome
    temLogo = (m.logoUrl <> "")
    m.logo.visible = temLogo
    m.tit.visible = not temLogo
    y = 240 + 18
    ' meta: nota, ano, duração, tag
    segs = []
    if m.notaTxt <> "" then segs.Push({ t: Chr(9733) + " " + m.notaTxt, cor: cNota(), neg: true })
    if m.anoTxt <> "" then segs.Push({ t: m.anoTxt, cor: "0xCCCCCCFF", neg: false })
    if m.durTxt <> "" then segs.Push({ t: m.durTxt, cor: "0xCCCCCCFF", neg: false })
    tag = "HD"
    if CreateObject("roRegex", "\b(4k|uhd)\b", "i").IsMatch(m.nomeBruto) then tag = "4K"
    m.tagTxt.text = tag
    total = 0
    larg = []
    for each s in segs
        w = vkMedir(s.t, 30, s.neg) + 6
        larg.Push(w)
        total = total + w + 22
    end for
    wt = 60
    total = total + wt
    x = Int((1920 - total) / 2)
    for i = 0 to 2
        m.metaL[i].visible = false
    end for
    for i = 0 to segs.Count() - 1
        l = m.metaL[i]
        l.visible = true
        l.text = segs[i].t
        l.color = segs[i].cor
        l.font = vkFonte(30, segs[i].neg)
        l.translation = [x, y]
        x = x + larg[i] + 22
    end for
    m.tagBg.translation = [x, y + 4]
    m.tagBg.width = wt
    m.tagTxt.translation = [x, y + 4]
    m.tagTxt.width = wt
    y = y + 44
    if m.generoTxt <> "" then
        y = y + 12
        m.genero.translation = [300, y]
        m.genero.text = m.generoTxt
        m.genero.visible = true
        y = y + 34
    else
        m.genero.visible = false
    end if
    cont = (m.alvo <> invalid and m.alvo.continuar = true and m.alvo.dur > 0)
    m.pgBg.visible = cont
    m.pgFill.visible = cont
    m.pgTxt.visible = cont
    if cont then
        y = y + 18
        m.pgBg.translation = [580, y + 12]
        m.pgBg.width = 760 - 24
        m.pgFill.translation = [580, y + 12]
        pct = m.alvo.pos / m.alvo.dur
        if pct > 1 then pct = 1
        m.pgFill.width = Int((760 - 24) * pct)
        m.pgTxt.translation = [580 + 760 - 12 + 12, y]
        m.pgTxt.text = textoRestam(m.alvo.dur - m.alvo.pos)
        m.pgTxt.width = 300
        ' barra mais curta para caber o texto "Restam ..." à direita
        m.pgBg.width = 560
        m.pgFill.width = Int(560 * pct)
        m.pgTxt.translation = [580 + 560 + 20, y]
        y = y + 32
    end if
    y = y + 22
    m.play.grupo.translation = [680, y]
    y = y + 92 + 18
    ' ações
    vis = []
    if cont then vis.Push(0)
    vis.Push(1)
    m.secVis = vis
    if m.secIdx > vis.Count() - 1 then m.secIdx = vis.Count() - 1
    m.sec[0].caixa.grupo.visible = false
    m.sec[1].caixa.grupo.visible = false
    tot = vis.Count() * 200 + (vis.Count() - 1) * 28
    x = Int((1920 - tot) / 2)
    for each k in vis
        m.sec[k].caixa.grupo.visible = true
        m.sec[k].caixa.grupo.translation = [x, y]
        x = x + 228
    end for
    y = y + 116 + 14
    m.sinopse.translation = [410, y]
    m.sinopse.text = m.sinopseTxt
    y = y + 117 + 34
    m.abasY = y
    ' abas
    larg = []
    tt = 0
    for i = 0 to m.abasUi.Count() - 1
        w = vkMedir(tx(m.abaNomes[i]), 30, true) + 80
        larg.Push(w)
        tt = tt + w
    end for
    x = Int((1920 - tt) / 2)
    for i = 0 to m.abasUi.Count() - 1
        b = m.abasUi[i]
        b.fundo.translation = [x, y - 4]
        b.fundo.width = larg[i]
        b.fundo.height = 70
        b.txt.translation = [x, y]
        b.txt.width = larg[i]
        b.sub.translation = [x, y + 66]
        b.sub.width = larg[i]
        x = x + larg[i]
    end for
    m.abaLinha.translation = [300, y + 68]
    m.contY = y + 70 + 20
    posicionarSecoes()
    pintar()
end sub

sub posicionarSecoes()
    cy = m.contY
    id = m.abaIds[m.abaIdx]
    ehEps = (id = "eps")
    ehSug = (id = "sug")
    ehDet = (id = "det")
    m.temp.grupo.visible = ehEps and not m.falha and m.temporadas.Count() > 0
    m.epJanela.visible = ehEps
    m.epMsg.visible = ehEps
    m.temp.grupo.translation = [304, cy]
    m.epJanela.translation = [300, cy + 68 + 14]
    m.epMsg.translation = [308, cy + 10]
    m.sugGrade.grupo.visible = ehSug
    m.sugGrade.grupo.translation = [304, cy]
    m.sugMsg.visible = ehSug
    m.sugMsg.translation = [308, cy + 10]
    m.detTit.visible = ehDet
    m.detSin.visible = ehDet
    for each l in m.detLin
        l.r.visible = ehDet
        l.v.visible = ehDet
    end for
    m.detTit.translation = [410, cy + 10]
    m.detSin.translation = [410, cy + 74]
    desenharDetalhes()
end sub

function textoRestam(seg as Integer) as String
    h = seg \ 3600
    mi = (seg mod 3600) \ 60
    if h = 0 and mi = 0 then return tx("Restam menos de 1min")
    if h > 0 then return tx("Restam") + " " + Str(h).Trim() + "h" + Str(mi).Trim() + "min"
    return tx("Restam") + " " + Str(mi).Trim() + "min"
end function

function formatarDur(seg as Integer) as String
    if seg < 60 then return ""
    h = seg \ 3600
    mi = (seg mod 3600) \ 60
    if h > 0 then return Str(h).Trim() + "h" + Right("0" + Str(mi).Trim(), 2) + "min"
    return Str(mi).Trim() + "min"
end function

' ── Foco / pintura ──────────────────────────────────────────────────
sub pintar()
    z = m.zona
    ' ASSISTIR
    if z = "play" then
        vkPintar(m.play, cClaro(), cBranco(), true)
        m.play.glow.opacity = 0.55
    else
        vkPintar(m.play, cBranco(), cBranco(), false)
    end if
    desab = (m.tipo = "series" and m.alvo = invalid)
    if desab then m.play.grupo.opacity = 0.5 else m.play.grupo.opacity = 1
    ' texto do botão e posição do ícone
    rot = "ASSISTIR"
    if m.alvo <> invalid then
        if m.alvo.continuar = true then rot = "CONTINUAR"
        if sv(m.alvo.rotulo) <> "" then rot = rot + " " + m.alvo.rotulo
    end if
    rot = tx(rot)
    m.playTxt.text = rot
    wt = vkMedir(rot, 36, true)
    m.playIco.translation = [Int((560 - wt - 50) / 2), 29]
    m.playTxt.translation = [26, 0]
    ' ações
    for each k in m.secVis
        a = m.sec[k]
        foco = (z = "sec" and m.secVis[m.secIdx] = k)
        if foco then
            vkPintar(a.caixa, cBranco(), "0xFFFFFF2E", true)
            a.caixa.glow.opacity = 0.45
        else
            vkPintar(a.caixa, "", "", false)
        end if
    end for
    fav = ehFavorito(m.tipo, m.id)
    if fav then
        m.sec[1].ico.uri = "pkg:/images/ui/i_estrela.png"
        m.sec[1].ico.blendColor = cNota()
    else
        m.sec[1].ico.uri = "pkg:/images/ui/i_estrela_vazia.png"
        m.sec[1].ico.blendColor = cBranco()
    end if
    ' abas
    for i = 0 to m.abasUi.Count() - 1
        b = m.abasUi[i]
        foco = (z = "abas" and i = m.abaIdx)
        sel = (i = m.abaIdx)
        b.fundo.visible = foco
        if foco or sel then
            b.txt.color = cBranco()
            b.sub.visible = true
        else
            b.txt.color = "0xFFFFFF8C"
            b.sub.visible = false
        end if
    end for
    ' temporada
    if z = "temp" then
        vkPintar(m.temp, cBranco(), cDest(), true)
        m.temp.glow.opacity = 0.45
    else
        vkPintar(m.temp, "", "0xFFFFFF1F", false)
    end if
    ' página sobe nas abas
    rolar = (z = "abas" or z = "temp" or z = "lista")
    if rolar then
        y = m.abasY - 110
        if y < 0 then y = 0
        m.pagina.translation = [0, -y]
    else
        m.pagina.translation = [0, 0]
    end if
    m.rolado.visible = rolar
    m.fade.visible = rolar
    m.sugGrade.ativo = (z = "lista")
    m.sugGrade.semSel = (z <> "lista")
    vkGradeDesenhar(m.sugGrade)
    desenharEpisodios()
end sub

' ── Botões / progresso ──────────────────────────────────────────────
function chaveProgresso() as String
    return "filme:" + m.id
end function

sub atualizarBotoes()
    if m.tipo = "filmes" then
        p = progressoDe(chaveProgresso())
        if p <> invalid and p.dur > 0 and p.pos > 20 and p.pos < p.dur - 90 then
            m.alvo = { continuar: true, pos: p.pos, dur: p.dur, rotulo: "" }
        else
            m.alvo = { continuar: false, pos: 0, dur: 0, rotulo: "" }
        end if
    else
        m.alvo = proximoEpisodio()
    end if
    relayout()
end sub

sub tocarPrincipal(doInicio as Boolean)
    try
        tocarPrincipalReal(doInicio)
    catch e
        print "[ERRO] Detalhe.assistir: "; sv(e.message); " #"; sv(e.number)
        uiAcao("erro", { texto: tx("Não foi possível reproduzir. Tente outro título ou canal.") })
    end try
end sub

sub tocarPrincipalReal(doInicio as Boolean)
    a = m.alvo
    if a = invalid then
        print "[ERRO] botao ASSISTIR sem episodio/filme (alvo vazio). tipo="; m.tipo
        uiAcao("erro", { texto: tx("Não foi possível reproduzir. Tente outro título ou canal.") })
        return
    end if
    ps = 0
    if not doInicio and a.continuar = true then ps = a.pos
    if m.tipo = "filmes" then
        tocarFilme(ps)
    else
        tocarEpisodio(a.t, a.e, ps)
    end if
end sub

sub alternarFav()
    alternarFavorito(m.tipo, { id: m.id, nome: m.nomeBruto, capa: m.capaUrl, ext: m.ext, cat: m.cat })
    pintar()
end sub

' ── Filme ───────────────────────────────────────────────────────────
sub aoInfoFilme(ev as Object)
    chamarFim(ev)
    pedirSugestoes()
    r = ev.getData()
    if r.ok <> true then return
    info = r.info
    m.info = info
    if r.dados <> invalid and sv(r.dados.container_extension) <> "" and not startsWith(m.ext, "http") then m.ext = sv(r.dados.container_extension)
    ano = sv(info.releasedate)
    if Len(ano) >= 4 then m.anoTxt = Left(ano, 4)
    seg = iv(info.duration_secs)
    if seg > 0 then m.durTxt = formatarDur(seg) else m.durTxt = sv(info.duration)
    n = uiNota(info.rating)
    if n <> "" then m.notaTxt = n
    if sv(info.genre) <> "" then m.generoTxt = generoBonito(sv(info.genre))
    m.plotPainel = sv(info.plot)
    if m.sinopseTxt = "" then m.sinopseTxt = m.plotPainel
    m.elenco = sv(info.cast)
    if m.elenco = "" then m.elenco = sv(info.actors)
    m.direcao = sv(info.director)
    m.lancamento = sv(info.releasedate)
    if idadeAdulta(info) and parentalBloqueando() then m.adulto = true
    if sv(info.backdrop_path) <> "" and m.fundoTmdb <> true then
        m.fundo.uri = sv(info.backdrop_path)
        m.fundo.opacity = 0.9
    end if
    relayout()
end sub

function generoBonito(g as String) as String
    rx = CreateObject("roRegex", "\s*[,/]\s*", "")
    p = rx.Split(g)
    saida = []
    for each x in p
        if x <> "" then
            if idiomaEn() then saida.Push(trCat(x)) else saida.Push(x)
        end if
    end for
    return saida.Join("  " + Chr(8226) + "  ")
end function

sub tocarFilme(posicao as Integer)
    if m.adulto = true and parentalBloqueando() then
        m.pend = { tipo: "filme", pos: posicao }
        uiSenha("Conteúdo protegido", "Digite a senha para assistir.", senhaOkReproduzir)
        return
    end if
    abrirPlayer(m.ext, posicao)
end sub

sub senhaOkReproduzir()
    p = m.pend
    if p = invalid then return
    if p.tipo = "filme" then
        abrirPlayer(m.ext, p.pos)
    else
        tocarEpisodio(p.t, p.e, p.pos)
    end if
end sub

sub abrirPlayer(ext as String, posicao as Integer)
    s = sessaoLer()
    if s = invalid then
        print "[ERRO] sessao invalida ao abrir filme"
        uiAcao("erro", { texto: tx("Usuário ou senha não conferem mais. Entre de novo.") })
        return
    end if
    url = ext
    if not startsWith(LCase(ext), "http") then
        e = ext
        if e = "" then e = "mp4"
        url = urlStream(s, "movie", m.id, e)
    end if
    uiAcao("abrir", { tela: "Player", args: {
        tipo: "filme", url: url, titulo: m.titulo, chave: chaveProgresso(), pos: posicao,
        reg: { tipo: "filmes", tid: m.id, nome: m.nomeBruto, capa: m.capaUrl, ext: m.ext }
    } })
end sub

' ── TMDB ────────────────────────────────────────────────────────────
sub aoTmdb(ev as Object)
    chamarFim(ev)
    r = ev.getData()
    if r.ok <> true then
        relayout()
        return
    end if
    if sv(r.titulo) <> "" then
        m.titulo = sv(r.titulo)
        m.tit.text = m.titulo
    end if
    if sv(r.sinopse) <> "" then
        m.sinopseTxt = sv(r.sinopse)
        m.tmdbSinopse = true
    end if
    if sv(r.fundo) <> "" then
        m.fundo.uri = sv(r.fundo)
        m.fundo.opacity = 0.9
        m.fundoTmdb = true
    end if
    if sv(r.logo) <> "" then
        m.logoUrl = sv(r.logo)
        m.logo.uri = m.logoUrl
    end if
    relayout()
end sub

' ── Série ───────────────────────────────────────────────────────────
sub aoInfoSerie(ev as Object)
    chamarFim(ev)
    pedirSugestoes()
    r = ev.getData()
    if r.ok <> true or r.temporadas.Count() = 0 then
        m.falha = true
        m.epMsg.text = tx("Não foi possível carregar os episódios. Aperte OK para tentar de novo.")
        if r.ok = true then m.epMsg.text = tx("Nenhum episódio disponível.")
        m.msgCarregando = false
        relayout()
        return
    end if
    m.falha = false
    info = r.info
    m.info = info
    ano = sv(info.releaseDate)
    if Len(ano) < 4 then ano = sv(info.release_date)
    if Len(ano) >= 4 then m.anoTxt = Left(ano, 4)
    n = uiNota(info.rating)
    if n <> "" then m.notaTxt = n
    if sv(info.genre) <> "" then m.generoTxt = generoBonito(sv(info.genre))
    m.plotPainel = sv(info.plot)
    if m.sinopseTxt = "" then m.sinopseTxt = m.plotPainel
    m.elenco = sv(info.cast)
    m.direcao = sv(info.director)
    m.lancamento = ano
    m.temporadas = r.temporadas
    if m.temporadas.Count() = 1 then
        m.durTxt = "1 " + tx("temporada")
    else
        m.durTxt = Str(m.temporadas.Count()).Trim() + " " + tx("temporadas")
    end if
    ' abre na temporada do próximo episódio
    p = proximoEpisodio()
    m.tempIdx = 0
    if p <> invalid then m.tempIdx = p.t
    m.epSel = 0
    if p <> invalid then m.epSel = p.e
    m.epTopo = Int(m.epSel / 4)
    m.msgCarregando = false
    m.epMsg.text = ""
    m.tempTxt.text = tx("Temporada") + " " + sv(m.temporadas[m.tempIdx].numero)
    ajustarTempBtn()
    atualizarBotoes()
    carregarTmdbTemp()
end sub

sub ajustarTempBtn()
    t = tx("Temporada") + " " + sv(m.temporadas[m.tempIdx].numero)
    m.tempTxt.text = t
    w = vkMedir(t, 30, true) + 34 + 18 + 34 + 6
    m.temp.borda.width = w
    m.temp.fundo.width = w - 6
    m.temp.glow.width = w + 12
    m.tempTxt.width = w
    m.tempSeta.translation = [w - 34 - 18, 28]
    m.tempSeta.visible = true
    m.temp.w = w
end sub

sub carregarTmdbTemp()
    m.tmdbEps = invalid
    if m.tempIdx >= m.temporadas.Count() then return
    t = chamar("TmdbTask", "temporada", { id: m.id, nome: m.nomeBruto, numero: sv(m.temporadas[m.tempIdx].numero) }, "aoTmdbTemp")
    marcarPedido("temp", t)
end sub

sub aoTmdbTemp(ev as Object)
    if not pedidoAtual("temp", ev) then return
    r = ev.getData()
    if r.ok = true then
        m.tmdbEps = r.eps
        desenharEpisodios()
    end if
end sub

' Título do episódio sem "Série S01E02 -".
function tituloEp(e as Object) as String
    t = sv(e.title).Trim()
    rx = CreateObject("roRegex", "^.*?\bS\d+\s*E\d+\b[\s\-–:._]*", "i")
    r = rx.Match(t)
    if r.Count() > 0 then
        t = Mid(t, Len(r[0]) + 1)
    else
        serie = m.nomeBruto.Trim()
        if serie <> "" and LCase(Left(t, Len(serie))) = LCase(serie) then t = Mid(t, Len(serie) + 1)
    end if
    rx2 = CreateObject("roRegex", "^[\s\-–:._]+", "")
    t = rx2.Replace(t, "").Trim()
    if t = "" then t = tx("Episódio") + " " + Str(e.episode_num).Trim()
    return t
end function

sub desenharEpisodios()
    if m.epCel = invalid then return
    id = m.abaIds[m.abaIdx]
    n = 0
    if m.tempIdx < m.temporadas.Count() then eps = m.temporadas[m.tempIdx].episodios else eps = []
    n = eps.Count()
    m.eps = eps
    for i = 0 to m.epCel.Count() - 1
        c = m.epCel[i]
        j = m.epTopo * 4 + i
        if id <> "eps" or j >= n then
            c.grupo.visible = false
        else
            e = eps[j]
            c.grupo.visible = true
            foco = (m.zona = "lista" and j = m.epSel)
            if foco then
                vkPintar(c.caixa, cBranco(), "0xE5091459", false)
            else
                vkPintar(c.caixa, "", "", false)
            end if
            numero = e.episode_num
            if numero = 0 then numero = j + 1
            nome = tituloEp(e)
            capa = sv(e.capa)
            if m.tmdbEps <> invalid then
                x = m.tmdbEps[Str(numero).Trim()]
                if x <> invalid then
                    if capa = "" then capa = sv(x.imagem)
                    gen = (nome = tx("Episódio") + " " + Str(numero).Trim())
                    if (idiomaEn() or gen) and sv(x.titulo) <> "" then nome = sv(x.titulo)
                end if
            end if
            if c.uri <> capa then
                c.capa.uri = capa
                c.uri = capa
            end if
            c.ini.text = Str(numero).Trim()
            c.ini.visible = (capa = "")
            c.num.text = Str(numero).Trim()
            c.tit.text = nome
            dur = sv(e.duracao)
            if iv(e.duracao_seg) > 0 then dur = formatarDur(iv(e.duracao_seg))
            p = progressoDe("ep:" + sv(e.id))
            c.pgBg.visible = false
            c.pgFill.visible = false
            if p <> invalid and p.dur > 0 then
                c.pgBg.visible = true
                c.pgFill.visible = true
                if p.pos >= p.dur - 90 then
                    c.pgFill.width = 309
                    c.pgFill.color = cOk()
                    if dur <> "" then dur = dur + "  " + Chr(8226) + "  " + tx("Assistido") else dur = tx("Assistido")
                else
                    c.pgFill.width = Int(309 * p.pos / p.dur)
                    c.pgFill.color = cClaro()
                end if
            end if
            c.dur.text = dur
        end if
    end for
    if id = "eps" and m.falha then
        m.epMsg.visible = true
    else if id = "eps" and m.msgCarregando then
        m.epMsg.text = tx("Carregando...")
        m.epMsg.visible = true
    else
        m.epMsg.visible = (id = "eps" and n = 0 and m.epMsg.text <> "")
    end if
end sub

' ── Sugestões ───────────────────────────────────────────────────────
sub aoSugestoes(ev as Object)
    chamarFim(ev)
    r = ev.getData()
    if r.ok <> true then
        m.sugMsg.text = tx("Sem sugestões por enquanto.")
        return
    end if
    base = []
    for each x in r.lista
        base.Push(normalizarItem(x))
    end for
    ps = -1
    for i = 0 to base.Count() - 1
        if base[i].id = m.id then
            ps = i
            exit for
        end if
    end for
    lista = []
    k = 1
    while k < base.Count() and lista.Count() < 12
        lista.Push(base[(ps + k + base.Count()) mod base.Count()])
        k = k + 1
    end while
    m.sugs = lista
    vis = []
    for each x in lista
        vis.Push({ nome: limparTitulo(x.nome), capa: x.capa })
    end for
    if lista.Count() = 0 then
        m.sugMsg.text = tx("Sem sugestões por enquanto.")
    else
        m.sugMsg.text = ""
    end if
    vkGradeItens(m.sugGrade, vis)
    m.sugGrade.semSel = (m.zona <> "lista")
    vkGradeDesenhar(m.sugGrade)
end sub

function normalizarItem(x as Object) as Object
    if m.tipo = "series" then
        return { id: sv(x.series_id), nome: sv(x.name), capa: urlImagem(x.cover), ext: "", cat: sv(x.category_id) }
    end if
    ext = sv(x.container_extension)
    if sv(x.url) <> "" then ext = sv(x.url)
    return { id: sv(x.stream_id), nome: sv(x.name), capa: urlImagem(x.stream_icon), ext: ext, cat: sv(x.category_id) }
end function

' ── Aba Detalhes ────────────────────────────────────────────────────
sub desenharDetalhes()
    m.detTit.text = m.titulo
    m.detSin.text = m.sinopseTxt
    if m.detSin.text = "" then m.detSin.text = tx("Sem sinopse disponível.")
    el = m.elenco
    if Len(el) > 220 then el = Left(el, 217) + "..."
    rot = []
    val = []
    if m.tipo = "series" then
        rot.Push(tx("Temporadas"))
        val.Push(Str(m.temporadas.Count()).Trim())
    else
        rot.Push(tx("Duração"))
        val.Push(m.durTxt)
    end if
    rot.Push(tx("Data de lançamento"))
    val.Push(m.lancamento)
    rot.Push(tx("Gênero"))
    val.Push(Substitute("{0}", m.generoTxt))
    rot.Push(tx("Direção"))
    val.Push(m.direcao)
    rot.Push(tx("Elenco"))
    val.Push(el)
    y = m.contY + 74 + 300 + 12
    if Len(m.detSin.text) < 300 then y = m.contY + 74 + 190
    k = 0
    for i = 0 to 4
        l = m.detLin[i]
        if val[i] = "" or val[i] = "0" then
            l.r.visible = false
            l.v.visible = false
        else
            vis = (m.abaIds[m.abaIdx] = "det")
            l.r.visible = vis
            l.v.visible = vis
            l.r.text = rot[i] + ":"
            l.v.text = val[i]
            wr = vkMedir(rot[i] + ":", 27, true) + 12
            l.r.translation = [410, y + k * 50]
            l.r.width = wr + 4
            l.v.translation = [410 + wr, y + k * 50]
            l.v.width = 1100 - wr
            k = k + 1
        end if
    end for
end sub

' ── Próximo episódio a assistir ─────────────────────────────────────
function proximoEpisodio() as Dynamic
    if m.temporadas.Count() = 0 then return invalid
    melhor = invalid
    tmax = 0
    for t = 0 to m.temporadas.Count() - 1
        eps = m.temporadas[t].episodios
        for e = 0 to eps.Count() - 1
            p = progressoDe("ep:" + sv(eps[e].id))
            if p <> invalid and p.dur > 0 and p.t >= tmax then
                tmax = p.t
                melhor = { t: t, e: e, p: p }
            end if
        end for
    end for
    if melhor = invalid then
        return { t: 0, e: 0, pos: 0, dur: 0, continuar: false, rotulo: "" }
    end if
    p = melhor.p
    ep = m.temporadas[melhor.t].episodios[melhor.e]
    if p.pos < p.dur - 90 and p.pos > 20 then
        return { t: melhor.t, e: melhor.e, pos: p.pos, dur: p.dur, continuar: true, rotulo: "T" + sv(m.temporadas[melhor.t].numero) + ":E" + Str(ep.episode_num).Trim() }
    end if
    t = melhor.t
    e = melhor.e + 1
    if e >= m.temporadas[t].episodios.Count() then
        t = t + 1
        e = 0
    end if
    if t >= m.temporadas.Count() then
        t = 0
        e = 0
    end if
    prox = m.temporadas[t].episodios[e]
    return { t: t, e: e, pos: 0, dur: 0, continuar: false, rotulo: "T" + sv(m.temporadas[t].numero) + ":E" + Str(prox.episode_num).Trim() }
end function

sub tocarEpisodio(t as Integer, e as Integer, posicao as Integer)
    if m.adulto = true and parentalBloqueando() then
        m.pend = { tipo: "ep", t: t, e: e, pos: posicao }
        uiSenha("Conteúdo protegido", "Digite a senha para assistir.", senhaOkReproduzir)
        return
    end if
    s = sessaoLer()
    if s = invalid then
        print "[ERRO] sessao invalida ao abrir episodio"
        uiAcao("erro", { texto: tx("Usuário ou senha não conferem mais. Entre de novo.") })
        return
    end if
    fila = []
    for tt = t to m.temporadas.Count() - 1
        eps = m.temporadas[tt].episodios
        ini = 0
        if tt = t then ini = e
        for ee = ini to eps.Count() - 1
            x = eps[ee]
            url = sv(x.url)
            if url = "" then
                ext = sv(x.container_extension)
                if ext = "" then ext = "mp4"
                url = urlStream(s, "series", sv(x.id), ext)
            end if
            fila.Push({ id: sv(x.id), url: url, titulo: "T" + sv(x.season) + " E" + Str(x.episode_num).Trim() + "  " + tituloEp(x) })
        end for
    end for
    uiAcao("abrir", { tela: "Player", args: {
        tipo: "episodio", titulo: m.titulo, pos: posicao, fila: fila, serie: m.id,
        reg: { tipo: "series", tid: m.id, nome: m.nomeBruto, capa: m.capaUrl, ext: "" }
    } })
end sub

sub tocarEpisodioSel()
    try
        tocarEpisodioSelReal()
    catch e
        print "[ERRO] Detalhe.episodio: "; sv(e.message); " #"; sv(e.number)
        uiAcao("erro", { texto: tx("Não foi possível reproduzir. Tente outro título ou canal.") })
    end try
end sub

sub tocarEpisodioSelReal()
    if m.epSel >= m.eps.Count() then return
    e = m.eps[m.epSel]
    p = progressoDe("ep:" + sv(e.id))
    posicao = 0
    if p <> invalid and p.dur > 0 and p.pos > 20 and p.pos < p.dur - 90 then posicao = p.pos
    tocarEpisodio(m.tempIdx, m.epSel, posicao)
end sub

' ── Janela das temporadas ───────────────────────────────────────────
sub abrirPopup()
    if m.temporadas.Count() = 0 then return
    m.popup = true
    itens = []
    for i = 0 to m.temporadas.Count() - 1
        it = { nome: tx("Temporada") + " " + sv(m.temporadas[i].numero) }
        if i = m.tempIdx then it.cor = cOk()
        itens.Push(it)
    end for
    m.popLista.idx = m.tempIdx
    vkListaItens(m.popLista, itens)
    vkListaIr(m.popLista, m.tempIdx)
    m.pop.visible = true
end sub

sub fecharPopup()
    m.popup = false
    m.pop.visible = false
end sub

sub escolherTemporada(i as Integer)
    m.tempIdx = i
    m.epSel = 0
    m.epTopo = 0
    ajustarTempBtn()
    fecharPopup()
    carregarTmdbTemp()
    pintar()
end sub

' ── Teclas ──────────────────────────────────────────────────────────
function onKeyEvent(tecla as String, pressionou as Boolean) as Boolean
    if not pressionou then return false
    if m.popup then return teclaPopup(tecla)
    if tecla = "back" then
        if m.zona = "abas" or m.zona = "temp" or m.zona = "lista" then
            m.zona = "play"
            pintar()
            return true
        end if
        uiAcao("voltar", invalid)
        return true
    end if
    if not (vkEhSeta(tecla) or tecla = "OK" or tecla = "rewind" or tecla = "fastforward") then return false
    z = m.zona
    if z = "play" then
        if tecla = "down" then
            m.zona = "sec"
            m.secIdx = 0
        else if tecla = "OK" then
            tocarPrincipal(false)
            return true
        end if
    else if z = "sec" then
        n = m.secVis.Count()
        if tecla = "left" then
            if m.secIdx > 0 then m.secIdx = m.secIdx - 1
        else if tecla = "right" then
            if m.secIdx < n - 1 then m.secIdx = m.secIdx + 1
        else if tecla = "up" then
            m.zona = "play"
        else if tecla = "down" then
            m.zona = "abas"
        else if tecla = "OK" then
            if m.secVis[m.secIdx] = 0 then tocarPrincipal(true) else alternarFav()
            return true
        end if
    else if z = "abas" then
        if tecla = "left" or tecla = "right" then
            novo = m.abaIdx - 1
            if tecla = "right" then novo = m.abaIdx + 1
            if novo >= 0 and novo < m.abaIds.Count() then
                m.abaIdx = novo
                posicionarSecoes()
            end if
        else if tecla = "up" then
            m.zona = "sec"
            if m.secIdx > m.secVis.Count() - 1 then m.secIdx = m.secVis.Count() - 1
        else
            entrarConteudo()
        end if
    else if z = "temp" then
        if tecla = "up" then
            m.zona = "abas"
        else if tecla = "down" then
            if m.eps.Count() > 0 then m.zona = "lista"
        else if tecla = "OK" then
            abrirPopup()
            return true
        end if
    else if z = "lista" then
        if m.abaIds[m.abaIdx] = "eps" then teclaEpisodios(tecla) else teclaSugestoes(tecla)
    end if
    pintar()
    return true
end function

sub entrarConteudo()
    id = m.abaIds[m.abaIdx]
    if id = "eps" then
        if m.falha then
            m.falha = false
            m.msgCarregando = true
            m.epMsg.text = ""
            chamar("ApiTask", "info_serie", { id: m.id }, "aoInfoSerie")
            posicionarSecoes()
        else if m.temporadas.Count() > 1 then
            m.zona = "temp"
        else if m.eps.Count() > 0 then
            m.zona = "lista"
        end if
    else if id = "sug" then
        if m.sugs.Count() > 0 then m.zona = "lista"
    end if
end sub

function teclaPopup(tecla as String) as Boolean
    l = m.popLista
    if tecla = "back" then
        fecharPopup()
    else if tecla = "up" then
        vkListaIr(l, l.idx - 1)
    else if tecla = "down" then
        vkListaIr(l, l.idx + 1)
    else if tecla = "OK" then
        escolherTemporada(l.idx)
    end if
    return true
end function

sub teclaSugestoes(tecla as String)
    g = m.sugGrade
    if tecla = "OK" then
        if g.idx < m.sugs.Count() then
            x = m.sugs[g.idx]
            uiAcao("abrir", { tela: "Detalhe", args: { tipo: m.tipo, id: x.id, nome: x.nome, capa: x.capa, ext: x.ext, cat: x.cat } })
        end if
        return
    end if
    if tecla = "up" and g.idx < 6 then
        m.zona = "abas"
        return
    end if
    vkGradeTecla(g, tecla)
end sub

sub teclaEpisodios(tecla as String)
    n = m.eps.Count()
    i = m.epSel
    if tecla = "left" then
        if i mod 4 > 0 then i = i - 1
    else if tecla = "right" then
        if i < n - 1 and i mod 4 < 3 then i = i + 1
    else if tecla = "up" then
        if i >= 4 then
            i = i - 4
        else
            if m.temporadas.Count() > 1 then m.zona = "temp" else m.zona = "abas"
        end if
    else if tecla = "down" then
        if i + 4 < n then
            i = i + 4
        else if Int(i / 4) < Int((n - 1) / 4) then
            i = n - 1
        end if
    else if tecla = "fastforward" then
        i = i + 8
        if i > n - 1 then i = n - 1
    else if tecla = "rewind" then
        i = i - 8
        if i < 0 then i = 0
    else if tecla = "OK" then
        tocarEpisodioSel()
        return
    end if
    m.epSel = i
    lin = Int(i / 4)
    if lin < m.epTopo then m.epTopo = lin
    if lin > m.epTopo + 1 then m.epTopo = lin - 1
end sub
