' VLTV Play - Roku | Home: mesmo layout da Home da LG/Samsung (topo, banner de destaque, 3 cartões, rodapé).
' Medidas em 1920x1080, iguais às do style.css da LG. Imagens em pkg:/images/home_*.

sub iniciar()
    carregarI18n()
    m.slides = []
    m.pos = 0
    m.foco = "t0"
    m.ultimoTile = 0
    m.tmdbMap = {}
    m.logoAtual = ""
    m.dias = ["dom", "seg", "ter", "qua", "qui", "sex", "sáb"]
    m.bnW = 1800
    m.bnEsq = 84
    m.bnComDs = false
    ' Destaque da semana (2º banner) e índice de títulos do painel
    m.ds = invalid
    m.dsMostrando = false
    m.dsBuscando = false
    m.dsChave = ""
    m.dsGer = 0
    m.dsFalhou = ""
    m.dsFalhouT = 0
    m.dsMap = {}
    m.idxEst = { filmes: "", series: "" }
    m.idxEsp = { filmes: [], series: [] }
    m.idxTask = {}
    m.achaMap = {}
    m.abrindo = false

    ' Fundo da tela (brilhos roxo/vermelho, listras e vinheta, como na LG)
    uiNo(m.top, "Poster", { translation: [0, 0], width: 1920, height: 1080, uri: "pkg:/images/home_fundo.jpg", loadDisplayMode: "scaleToFill" })

    ' Topo: logo à esquerda; hora, data, aviso e engrenagem à direita
    uiNo(m.top, "Poster", { translation: [60, 90], width: 324, height: 60, uri: "pkg:/images/home_logo.png", loadDisplayMode: "scaleToFit" })
    m.hora = uiNo(m.top, "Label", { translation: [1120, 82], width: 640, height: 28, horizAlign: "right", vertAlign: "center", font: fonteHome(false, 24), color: uiSuave() })
    m.data = uiNo(m.top, "Label", { translation: [1120, 122], width: 640, height: 30, horizAlign: "right", vertAlign: "center", font: fonteHome(false, 26), color: uiSuave() })
    m.aviso = uiNo(m.top, "Label", { translation: [1120, 160], width: 640, height: 30, horizAlign: "right", vertAlign: "top", wrap: true, font: fonteHome(false, 22), color: "0xFFB020FF" })
    m.gearN = uiNo(m.top, "Poster", { translation: [1784, 82], width: 76, height: 76, uri: "pkg:/images/home_engrenagem.png", loadDisplayMode: "scaleToFit" })
    m.gearF = uiNo(m.top, "Poster", { translation: [1776, 74], width: 92, height: 92, uri: "pkg:/images/home_engrenagem_foco.png", loadDisplayMode: "scaleToFit", visible: false })

    montarBanner()
    montarDestaque()
    montarTiles()
    montarRodape()
    montarCampanha()

    m.relogio = uiNo(m.top, "Timer", { repeat: true, duration: 15 })
    m.relogio.observeField("fire", "tique")
    m.relogio.control = "start"
    m.giro = uiNo(m.top, "Timer", { repeat: true, duration: 8 })
    m.giro.observeField("fire", "girar")
    ' a cada 1 min confere no painel se o Destaque da semana / campanha mudou (sem precisar fechar o app)
    m.tVisual = uiNo(m.top, "Timer", { repeat: true, duration: 60 })
    m.tVisual.observeField("fire", "tiqueVisual")
    m.tVisual.control = "start"
    ' depois que a Home já está na tela, baixa/atualiza o índice de títulos (serve ao banner, ao destaque e à pesquisa)
    m.tAquecer = uiNo(m.top, "Timer", { repeat: false, duration: 4 })
    m.tAquecer.observeField("fire", "aquecerCatalogo")
    m.tAquecer.control = "start"
    m.tIndice = uiNo(m.top, "Timer", { repeat: false, duration: 8 })
    m.tIndice.observeField("fire", "iniciarIndicesHome")
    m.tIndice.control = "start"
    m.tAvisoBn = uiNo(m.top, "Timer", { repeat: false, duration: 3 })
    m.tAvisoBn.observeField("fire", "fimAvisoBanner")

    aplicarFoco()
    m.top.setFocus(true)
    ' O topo (hora, data, avisos) nunca pode impedir a Home de funcionar: se algo falhar aqui, só registra.
    try
        aplicarVisual()
        tique()
    catch e
        print "VLTV Home: erro no topo: "; e.message
    end try
    t = chamar("ApiTask", "banner", { modo: "cache" }, "aoBannerCache")
    atualizarDestaque()
end sub

sub retomar()
    ' voltou de outra tela: o controle parental trava de novo na Home
    m.global.parentalLiberado = false
    tique()
    m.giro.control = "start"
    m.abrindo = false
    ' índice que falhou antes: tenta de novo na próxima volta à Home
    if m.idxEst.filmes = "erro" then m.idxEst.filmes = ""
    if m.idxEst.series = "erro" then m.idxEst.series = ""
    atualizarDestaque()
    aplicarFoco()
    m.top.setFocus(true)
end sub

sub encerrar()
    m.relogio.control = "stop"
    m.giro.control = "stop"
    m.tVisual.control = "stop"
    m.tIndice.control = "stop"
end sub

' ── Ajudantes ───────────────────────────────────────────────────────
function fonteHome(negrito as Boolean, tam as Integer) as Object
    f = CreateObject("roSGNode", "Font")
    if negrito then
        f.uri = "pkg:/images/LiberationSans-Bold.ttf"
    else
        f.uri = "pkg:/images/LiberationSans-Regular.ttf"
    end if
    f.size = tam
    return f
end function

function imagemHome(pai as Object, x as Integer, y as Integer, w as Integer, h as Integer, arq as String, modo as String) as Object
    return uiNo(pai, "Poster", { translation: [x, y], width: w, height: h, uri: "pkg:/images/" + arq, loadDisplayMode: modo })
end function

function medirHome(lbl as Object, tam as Integer) as Integer
    r = lbl.boundingRect()
    if r <> invalid then
        if r.width > 0 then return Int(r.width + 0.5)
    end if
    return Int(Len(sv(lbl.text)) * tam * 0.55)
end function
' ── Banner de destaque (1800x510 em 60,202; encolhe para 1100x510 quando o Destaque da semana está ligado) ──
sub montarBanner()
    m.bn = uiNo(m.top, "Group", { translation: [60, 202] })
    m.bnBase = uiRet(m.bn, 0, 0, 1800, 510, "0x141416FF")

    ' área de dentro da borda (4px): corta o fundo para não vazar
    m.bnClip = uiNo(m.bn, "Group", { translation: [4, 4], clippingRect: [0, 0, 1792, 502] })
    m.bnFundo = uiNo(m.bnClip, "Poster", { translation: [0, 0], width: 1792, height: 502, loadDisplayMode: "scaleToFill" })
    m.bnFundo.observeField("loadStatus", "aoFundoCarregou")
    m.bnGrad = uiNo(m.bnClip, "Poster", { translation: [0, 0], width: 1792, height: 502, loadDisplayMode: "scaleToFill" })

    ' estado vazio (antes de chegar o primeiro destaque)
    m.bnVazio = uiNo(m.bn, "Group", {})
    m.bnVazioRet = uiRet(m.bnVazio, 4, 4, 1792, 502, "0x121214FF")
    m.bnVazioLogo = imagemHome(m.bnVazio, 84, 205, 518, 97, "home_logo_vazio.png", "scaleToFit")

    m.bnConteudo = uiNo(m.bn, "Group", { visible: false })
    m.bnCapa = uiNo(m.bnConteudo, "Poster", { translation: [1416, 40], width: 310, height: 430, loadDisplayMode: "scaleToZoom" })
    m.bnLogo = uiNo(m.bnConteudo, "Poster", { translation: [84, 92], width: 720, height: 170, loadDisplayMode: "scaleToFit", visible: false })
    m.bnLogo.observeField("loadStatus", "aoLogoCarregou")
    m.bnTitulo = uiNo(m.bnConteudo, "Label", { translation: [84, 92], width: 1000, height: 170, wrap: true, maxLines: 2, vertAlign: "bottom", font: fonteHome(true, 68), color: uiTexto() })
    m.bnEstrela = imagemHome(m.bnConteudo, 84, 281, 28, 28, "home_estrela.png", "scaleToFit")
    m.bnMeta = uiNo(m.bnConteudo, "Label", { translation: [84, 278], width: 1000, height: 33, vertAlign: "center", font: fonteHome(false, 28), color: "0xFFFFFFD9" })

    ' botão ASSISTIR (pílula branca)
    m.bnBtn = novaPilula(m.bnConteudo, tx("ASSISTIR"), 32)
    m.bnPontos = uiNo(m.bnConteudo, "Group", { translation: [84, 468] })

    ' cantos arredondados e moldura de foco
    m.bnCantos = imagemHome(m.bn, 0, 0, 1800, 510, "home_cantos.png", "scaleToFit")
    m.bnFoco = uiNo(m.top, "Poster", { translation: [52, 194], width: 1816, height: 526, uri: "pkg:/images/home_banner_foco.png", loadDisplayMode: "scaleToFit", visible: false })
    ajustarBanner(false)
end sub

' Pílula branca com o ícone de play e o texto (3 pedaços de imagem + ícone + texto por cima).
function novaPilula(pai as Object, texto as String, tam as Integer) as Object
    b = {}
    b.e = imagemHome(pai, 0, 0, 39, 78, "home_pilula_esq.png", "scaleToFill")
    b.m = imagemHome(pai, 0, 0, 39, 78, "home_pilula_meio.png", "scaleToFill")
    b.d = imagemHome(pai, 0, 0, 39, 78, "home_pilula_dir.png", "scaleToFill")
    b.p = imagemHome(pai, 0, 0, 34, 34, "home_play.png", "scaleToFit")
    b.txt = uiNo(pai, "Label", { translation: [0, 0], height: 78, vertAlign: "center", font: fonteHome(true, tam), color: "0x0A0A0CFF", text: texto })
    return b
end function

sub layoutPilula(b as Object, x as Integer, y as Integer, h as Integer, cap as Integer, pad as Integer, ico as Integer, tam as Integer)
    b.txt.font = fonteHome(true, tam)
    larg = pad + ico + 12 + medirHome(b.txt, tam) + pad
    b.e.translation = [x, y]
    b.e.width = cap
    b.e.height = h
    b.m.translation = [x + cap, y]
    b.m.width = larg - 2 * cap
    b.m.height = h
    b.d.translation = [x + larg - cap, y]
    b.d.width = cap
    b.d.height = h
    b.p.translation = [x + pad, y + Int((h - ico) / 2)]
    b.p.width = ico
    b.p.height = ico
    b.txt.translation = [x + pad + ico + 12, y]
    b.txt.height = h
end sub

' Banner de destaques com ou sem o Destaque da semana ao lado (mesmas medidas do style.css da LG).
sub ajustarBanner(comDs as Boolean)
    m.bnComDs = comDs
    if comDs then
        w = 1100
        m.bnEsq = 54
        m.bnLogoMaxW = 580
        m.bnLogoMaxH = 150
        m.bnCaixaY = 115
        m.bnCaixaH = 150
        m.bnMetaY = 277
        m.bnMetaH = 30
        m.bnEstTam = 24
        m.bnEstOff = 32
        m.bnCapa.translation = [w - 74 - 250, 80]
        m.bnCapa.width = 250
        m.bnCapa.height = 350
        m.bnTitulo.width = 660
        m.bnTitulo.font = fonteHome(true, 52)
        m.bnMeta.font = fonteHome(false, 24)
        m.bnCantos.uri = "pkg:/images/home_cantos_1100.png"
        m.bnFoco.uri = "pkg:/images/home_banner_foco_1100.png"
        m.bnFoco.width = 1116
        m.bnVazioLogo.translation = [54, 215]
        m.bnVazioLogo.width = 400
        m.bnVazioLogo.height = 75
        layoutPilula(m.bnBtn, 54, 329, 66, 33, 36, 28, 28)
    else
        w = 1800
        m.bnEsq = 84
        m.bnLogoMaxW = 720
        m.bnLogoMaxH = 170
        m.bnCaixaY = 92
        m.bnCaixaH = 170
        m.bnMetaY = 278
        m.bnMetaH = 33
        m.bnEstTam = 28
        m.bnEstOff = 36
        m.bnCapa.translation = [1416, 40]
        m.bnCapa.width = 310
        m.bnCapa.height = 430
        m.bnTitulo.width = 1000
        m.bnTitulo.font = fonteHome(true, 68)
        m.bnMeta.font = fonteHome(false, 28)
        m.bnCantos.uri = "pkg:/images/home_cantos.png"
        m.bnFoco.uri = "pkg:/images/home_banner_foco.png"
        m.bnFoco.width = 1816
        m.bnVazioLogo.translation = [84, 205]
        m.bnVazioLogo.width = 518
        m.bnVazioLogo.height = 97
        layoutPilula(m.bnBtn, 84, 340, 78, 39, 44, 34, 32)
    end if
    m.bnW = w
    iw = w - 8
    m.bnBase.width = w
    m.bnClip.clippingRect = [0, 0, iw, 502]
    m.bnGrad.width = iw
    m.bnVazioRet.width = iw
    m.bnCantos.width = w
    m.bnTitulo.translation = [m.bnEsq, m.bnCaixaY]
    m.bnTitulo.height = m.bnCaixaH
    m.bnLogo.translation = [m.bnEsq, m.bnCaixaY]
    m.bnLogo.width = m.bnLogoMaxW
    m.bnLogo.height = m.bnCaixaH
    m.bnEstrela.width = m.bnEstTam
    m.bnEstrela.height = m.bnEstTam
    m.bnMeta.height = m.bnMetaH
    m.bnPontos.translation = [m.bnEsq, 468]
    if m.slides.Count() > 0 then
        mostrarSlide()
        aoFundoCarregou()
        ' o logo já carregado precisa ser medido de novo no novo tamanho
        if m.bnLogo.loadStatus = "ready" and m.logoAtual <> "" then aoLogoCarregou()
    end if
end sub
' ── Destaque da semana (676x510 em 1184,202; só aparece quando o painel liga) ──
sub montarDestaque()
    m.dsG = uiNo(m.top, "Group", { translation: [1184, 202], visible: false })
    uiRet(m.dsG, 0, 0, 676, 510, "0x141416FF")
    m.dsClip = uiNo(m.dsG, "Group", { translation: [4, 4], clippingRect: [0, 0, 668, 502] })
    m.dsFundo = uiNo(m.dsClip, "Poster", { translation: [0, 0], width: 668, height: 502, loadDisplayMode: "scaleToFill" })
    m.dsFundo.observeField("loadStatus", "aoDsFundoCarregou")
    m.dsGrad = uiNo(m.dsClip, "Poster", { translation: [0, 0], width: 668, height: 502, uri: "pkg:/images/home_grad_ds.png", loadDisplayMode: "scaleToFill" })
    m.dsEtq = uiNo(m.dsG, "Label", { translation: [48, 0], width: 580, height: 30, vertAlign: "center", font: fonteHome(true, 24), color: "0xFFD700FF", text: tx("DESTAQUE DA SEMANA") })
    m.dsLogo = uiNo(m.dsG, "Poster", { translation: [48, 0], width: 520, height: 130, loadDisplayMode: "scaleToFit", visible: false })
    m.dsLogo.observeField("loadStatus", "aoDsLogoCarregou")
    m.dsTit = uiNo(m.dsG, "Label", { translation: [48, 0], width: 580, height: 130, wrap: true, maxLines: 2, vertAlign: "bottom", font: fonteHome(true, 46), color: uiTexto() })
    m.dsEstrela = imagemHome(m.dsG, 48, 0, 24, 24, "home_estrela.png", "scaleToFit")
    m.dsMeta = uiNo(m.dsG, "Label", { translation: [48, 0], width: 580, height: 30, vertAlign: "center", font: fonteHome(false, 24), color: "0xFFFFFFD9" })
    m.dsSin = uiNo(m.dsG, "Label", { translation: [48, 0], width: 580, height: 87, wrap: true, maxLines: 3, vertAlign: "top", font: fonteHome(false, 22), color: "0xFFFFFFD9" })
    m.dsBtn = novaPilula(m.dsG, tx("ASSISTIR"), 28)
    layoutPilula(m.dsBtn, 48, 400, 66, 33, 36, 28, 28)
    imagemHome(m.dsG, 0, 0, 676, 510, "home_cantos_676.png", "scaleToFit")
    m.dsFoco = uiNo(m.top, "Poster", { translation: [1176, 194], width: 692, height: 526, uri: "pkg:/images/home_banner_foco_676.png", loadDisplayMode: "scaleToFit", visible: false })
    m.dsHLogo = 0
end sub

' ── Cartões: TV ao vivo, Filmes, Séries ─────────────────────────────
sub montarTiles()
    m.tiles = []
    nomes = ["live", "filmes", "series"]
    titulos = ["TV ao vivo", "Filmes", "Séries"]
    subs = ["Canais e programação", "Catálogo de filmes", "Temporadas e episódios"]
    for i = 0 to 2
        g = uiNo(m.top, "Group", { translation: [60 + i * 608, 738], scaleRotateCenter: [292, 80] })
        n = imagemHome(g, 0, 0, 584, 160, "home_tile_" + nomes[i] + ".png", "scaleToFit")
        f = imagemHome(g, -8, -8, 600, 176, "home_tile_" + nomes[i] + "_foco.png", "scaleToFit")
        f.visible = false
        uiNo(g, "Label", { translation: [40, 38], width: 504, height: 46, vertAlign: "center", font: fonteHome(true, 40), color: uiTexto(), text: tx(titulos[i]) })
        uiNo(g, "Label", { translation: [40, 91], width: 504, height: 29, vertAlign: "center", font: fonteHome(false, 25), color: "0xFFFFFFD1", text: tx(subs[i]) })
        m.tiles.Push({ grupo: g, normal: n, foco: f })
    end for
end sub

' ── Rodapé: Listas (esquerda) e Sair (direita) ──────────────────────
function criarBotao(texto as String, x as Integer, alinharDireita as Boolean) as Object
    lbl = uiNo(m.top, "Label", { height: 48, vertAlign: "center", horizAlign: "center", font: fonteHome(false, 24), color: uiSuave(), text: tx(texto) })
    w = 60 + medirHome(lbl, 24)
    if alinharDireita then x = x - w
    y = 972
    b = { x: x, w: w, lbl: lbl, n: [], f: []}
    b.n.Push(imagemHome(m.top, x, y, 24, 48, "home_btn_esq.png", "scaleToFill"))
    b.n.Push(imagemHome(m.top, x + 24, y, w - 48, 48, "home_btn_meio.png", "scaleToFill"))
    b.n.Push(imagemHome(m.top, x + w - 24, y, 24, 48, "home_btn_dir.png", "scaleToFill"))
    b.f.Push(imagemHome(m.top, x, y, 24, 48, "home_btn_foco_esq.png", "scaleToFill"))
    b.f.Push(imagemHome(m.top, x + 24, y, w - 48, 48, "home_btn_foco_meio.png", "scaleToFill"))
    b.f.Push(imagemHome(m.top, x + w - 24, y, 24, 48, "home_btn_foco_dir.png", "scaleToFill"))
    for each p in b.f
        p.visible = false
    end for
    lbl.translation = [x, y]
    lbl.width = w
    ' o texto fica por cima dos fundos
    m.top.removeChild(lbl)
    m.top.appendChild(lbl)
    return b
end function

sub montarRodape()
    m.btnListas = criarBotao("Listas", 60, false)
    m.btnSair = criarBotao("Sair", 1860, true)
end sub

sub pintarBotao(b as Object, ligado as Boolean)
    for each p in b.n
        p.visible = not ligado
    end for
    for each p in b.f
        p.visible = ligado
    end for
    if ligado then
        b.lbl.color = "0xFFFFFFFF"
    else
        b.lbl.color = uiSuave()
    end if
end sub

' ── Faixa de campanha (centro, no topo) ─────────────────────────────
sub montarCampanha()
    m.camp = uiNo(m.top, "Group", { translation: [960, 10], visible: false })
    m.campFundo = uiRet(m.camp, 0, 0, 100, 34, "0xFFFFFF12")
    m.campTopo = uiRet(m.camp, 0, 0, 100, 1, "0x2E2E34FF")
    m.campBase = uiRet(m.camp, 0, 33, 100, 1, "0x2E2E34FF")
    m.campDir = uiRet(m.camp, 99, 0, 1, 34, "0x2E2E34FF")
    m.campCor = uiRet(m.camp, 0, 0, 4, 34, "0xFF4B55FF")
    m.campTxt = uiNo(m.camp, "Label", { translation: [26, 0], height: 34, vertAlign: "center", font: fonteHome(true, 20), color: uiSuave() })
end sub

' ── Hora, data e avisos ─────────────────────────────────────────────
sub tique()
    m.hora.text = horaAgora()
    d = CreateObject("roDateTime")
    d.ToLocalTime()
    dia = d.GetDayOfMonth()
    mes = d.GetMonth()
    txt = m.dias[d.GetDayOfWeek()] + ", "
    if dia < 10 then txt = txt + "0"
    txt = txt + Str(dia).Trim() + "/"
    if mes < 10 then txt = txt + "0"
    txt = txt + Str(mes).Trim() + "/" + Str(d.GetYear()).Trim()
    m.data.text = txt
    try
        avisos()
    catch e
        print "VLTV Home: erro nos avisos: "; e.message
    end try
end sub

sub avisos()
    ' Aviso de vencimento/teste: texto laranja embaixo da data
    exp = 0
    inf = m.global.info
    if inf <> invalid then
        if isAA(inf) then exp = iv(inf.exp_date)
    end if
    textos = licAvisos(m.global.lic, m.global.ehParceiro, exp)
    linhas = 0
    if textos.Count() > 0 then
        t = ""
        for each x in textos
            if t <> "" then t = t + "  •  "
            t = t + tx(sv(x))
        end for
        m.aviso.text = t
        linhas = Int(Len(t) * 11 / 640) + 1
        if linhas > 3 then linhas = 3
        m.aviso.height = linhas * 29
        m.aviso.visible = true
    else
        m.aviso.text = ""
        m.aviso.visible = false
    end if
    ' o bloco do topo (hora, data, aviso) cresce e fica centralizado na altura de 120
    alt = 70
    if linhas > 0 then alt = 78 + linhas * 29
    if alt < 76 then alt = 76
    topo = 60 + Int((120 - alt) / 2)
    m.hora.translation = [1120, topo]
    m.data.translation = [1120, topo + 40]
    m.aviso.translation = [1120, topo + 78]
    m.gearN.translation = [1784, topo]
    m.gearF.translation = [1776, topo - 8]
    campanha()
end sub

sub campanha()
    v = m.global.visual
    vale = false
    t = ""
    cor = "0xFF4B55FF"
    if v <> invalid then
        if isAA(v) then
            if sv(v.aviso_texto) <> "" then
                vale = true
                ate = sv(v.aviso_ate)
                if Len(ate) = 10 then
                    hoje = CreateObject("roDateTime")
                    h = hoje.ToISOString()
                    if Left(h, 10) > ate then vale = false
                end if
                if vale then
                    t = sv(v.aviso_texto)
                    if sv(v.aviso_titulo) <> "" then t = sv(v.aviso_titulo) + " — " + t
                    c = sv(v.aviso_cor)
                    if Len(c) = 7 and Left(c, 1) = "#" then cor = "0x" + UCase(Mid(c, 2)) + "FF"
                end if
            end if
        end if
    end if
    if not vale then
        m.camp.visible = false
        return
    end if
    m.campTxt.text = t
    larg = medirHome(m.campTxt, 20) + 52
    if larg > 900 then larg = 900
    m.campTxt.width = larg - 48
    m.campFundo.width = larg
    m.campTopo.width = larg
    m.campBase.width = larg
    m.campDir.translation = [larg - 1, 0]
    m.campCor.color = cor
    m.camp.translation = [960 - Int(larg / 2), 10]
    m.camp.visible = true
end sub
sub aplicarVisual()
    avisos()
    try
        atualizarDestaque()
    catch e
        print "VLTV Home: erro no destaque: "; e.message
    end try
end sub

' ── Destaque ────────────────────────────────────────────────────────
sub aoBannerCache(ev as Object)
    chamarFim(ev)
    r = ev.getData()
    if r.ok = true then usarSlides(r.slides)
    chamar("ApiTask", "banner", { modo: "rede" }, "aoBannerRede")
end sub

sub aoBannerRede(ev as Object)
    chamarFim(ev)
    r = ev.getData()
    if r.ok = true and r.slides.Count() > 0 then usarSlides(r.slides)
end sub

sub usarSlides(recebidos as Object)
    ' cópia própria dos destaques (a tela acrescenta logo e fundo do TMDB neles)
    lista = []
    for each x in recebidos
        c = {}
        c.Append(x)
        lista.Push(c)
    end for
    m.slides = lista
    if m.pos >= lista.Count() then m.pos = 0
    mostrarSlide()
    m.giro.control = "start"
    ' logo e imagem de fundo do TMDB de cada destaque (guardados na TV depois da primeira vez).
    ' Um destaque por vez: o atual primeiro, depois os outros (não disputa a rede com o resto do app).
    m.tmdbMap = {}
    if m.tmdbGer = invalid then m.tmdbGer = 0
    m.tmdbGer = m.tmdbGer + 1
    m.tmdbOrdem = []
    m.tmdbOrdem.Push(m.pos)
    for i = 0 to lista.Count() - 1
        if i <> m.pos then m.tmdbOrdem.Push(i)
    end for
    m.tmdbPasso = 0
    pedirTmdbSlide()
end sub

sub pedirTmdbSlide()
    if m.tmdbPasso >= m.tmdbOrdem.Count() then return
    i = m.tmdbOrdem[m.tmdbPasso]
    if i >= m.slides.Count() then return
    s = m.slides[i]
    id = sv(s.id)
    if s.daVps = true then id = "vps" + id
    t = chamar("TmdbTask", "detalhe", { tipo: sv(s.tipo), id: id, nome: sv(s.nomeBruto) }, "aoTmdbSlide")
    m.tmdbMap[t.id] = { i: i, ger: m.tmdbGer }
end sub

sub aoTmdbSlide(ev as Object)
    n = ev.getRoSGNode()
    chamarFim(ev)
    r = ev.getData()
    info = m.tmdbMap[n.id]
    if info = invalid then return
    m.tmdbMap.Delete(n.id)
    if info.ger <> m.tmdbGer then return   ' veio de uma lista antiga de destaques
    m.tmdbPasso = m.tmdbPasso + 1
    pedirTmdbSlide()
    i = info.i
    if r.ok <> true then return
    if i >= m.slides.Count() then return
    s = m.slides[i]
    mudou = false
    if sv(r.fundo) <> "" and sv(s.fundo) <> sv(r.fundo) then
        s.fundo = sv(r.fundo)
        mudou = true
    end if
    if sv(r.logo) <> "" and sv(s.logo) <> sv(r.logo) then
        s.logo = sv(r.logo)
        mudou = true
    end if
    if idiomaEn() and sv(r.titulo) <> "" then s.nomeEn = sv(r.titulo)
    if mudou and i = m.pos then mostrarSlide()
end sub

sub mostrarSlide()
    if m.slides.Count() = 0 then
        m.bnVazio.visible = true
        m.bnConteudo.visible = false
        m.bnFundo.uri = ""
        m.bnGrad.uri = ""
        return
    end if
    s = m.slides[m.pos]
    m.bnVazio.visible = false
    m.bnConteudo.visible = true
    ' fundo: imagem nítida do TMDB, ou a capa do servidor com o pôster ao lado
    if sv(s.fundo) <> "" then
        m.bnFundo.uri = sv(s.fundo)
        m.bnGrad.uri = "pkg:/images/home_grad_fundo.png"
        m.bnCapa.visible = false
    else
        m.bnFundo.uri = sv(s.capa)
        m.bnGrad.uri = "pkg:/images/home_grad_capa.png"
        m.bnCapa.uri = sv(s.capa)
        m.bnCapa.visible = true
    end if
    nome = sv(s.nome)
    if idiomaEn() and sv(s.nomeEn) <> "" then nome = sv(s.nomeEn)
    m.bnTitulo.text = nome
    logo = sv(s.logo)
    if logo <> "" then
        if m.logoAtual = logo then
            ' mesma imagem de antes: já está carregada, só mostra
            m.bnTitulo.visible = false
            m.bnLogo.visible = true
        else
            m.logoAtual = logo
            m.bnTitulo.visible = false
            m.bnLogo.visible = false
            m.bnLogo.uri = logo
        end if
    else
        m.logoAtual = ""
        m.bnLogo.visible = false
        m.bnLogo.uri = ""
        m.bnTitulo.visible = true
    end if
    ' a estrela é uma imagem (a fonte não tem esse caractere); o texto começa depois dela
    meta = ""
    esq = m.bnEsq
    m.bnEstrela.visible = false
    if sv(s.nota) <> "" then
        meta = sv(s.nota)
        m.bnEstrela.visible = true
        esq = m.bnEsq + m.bnEstOff
    end if
    m.bnEstrela.translation = [m.bnEsq, m.bnMetaY + 3]
    m.bnMeta.translation = [esq, m.bnMetaY]
    if sv(s.ano) <> "" then
        if meta <> "" then meta = meta + "   •   "
        meta = meta + sv(s.ano)
    end if
    if meta <> "" then meta = meta + "   •   "
    if sv(s.tipo) = "series" then
        meta = meta + tx("Série")
    else
        meta = meta + tx("Filme")
    end if
    m.bnMeta.text = meta
    desenharPontos()
end sub

' Pontos de baixo do banner: o do destaque atual é comprido e branco
sub desenharPontos()
    while m.bnPontos.getChildCount() > 0
        m.bnPontos.removeChildIndex(0)
    end while
    x = 0
    for i = 0 to m.slides.Count() - 1
        if i = m.pos then
            imagemHome(m.bnPontos, x, 0, 38, 14, "home_ponto_sel.png", "scaleToFit")
            x = x + 38 + 10
        else
            imagemHome(m.bnPontos, x, 0, 14, 14, "home_ponto.png", "scaleToFit")
            x = x + 14 + 10
        end if
    end for
end sub
sub aoFundoCarregou()
    if m.bnFundo.loadStatus <> "ready" then return
    bw = m.bnFundo.bitmapWidth
    bh = m.bnFundo.bitmapHeight
    if bw <= 0 or bh <= 0 then return
    iw = m.bnW - 8
    e = iw / bw
    e2 = 502 / bh
    if e2 > e then e = e2
    w = bw * e
    h = bh * e
    m.bnFundo.width = w
    m.bnFundo.height = h
    m.bnFundo.translation = [(iw - w) / 2, 0]
end sub
sub aoLogoCarregou()
    st = m.bnLogo.loadStatus
    if st = "failed" then
        m.bnLogo.visible = false
        m.bnTitulo.visible = true
        return
    end if
    if st <> "ready" then return
    bw = m.bnLogo.bitmapWidth
    bh = m.bnLogo.bitmapHeight
    if bw <= 0 or bh <= 0 then return
    e = 1.0
    if bw * e > m.bnLogoMaxW then e = m.bnLogoMaxW / bw
    if bh * e > m.bnLogoMaxH then e = m.bnLogoMaxH / bh
    w = Int(bw * e)
    h = Int(bh * e)
    m.bnLogo.width = w
    m.bnLogo.height = h
    m.bnLogo.translation = [m.bnEsq, m.bnCaixaY + m.bnCaixaH - h]
    m.bnLogo.visible = true
    m.bnTitulo.visible = false
end sub

sub girar()
    if m.slides.Count() < 2 then return
    mover(1)
end sub

sub mover(passo as Integer)
    n = m.slides.Count()
    if n < 2 then return
    m.pos = (m.pos + passo + n) mod n
    mostrarSlide()
    m.giro.control = "start"
end sub

' ── Foco ────────────────────────────────────────────────────────────
sub aplicarFoco()
    f = m.foco
    m.bnFoco.visible = (f = "banner")
    m.dsFoco.visible = (f = "ds")
    m.gearN.visible = (f <> "gear")
    m.gearF.visible = (f = "gear")
    for i = 0 to 2
        ligado = (f = "t" + Str(i).Trim())
        m.tiles[i].normal.visible = not ligado
        m.tiles[i].foco.visible = ligado
        if ligado then
            m.tiles[i].grupo.scale = [1.03, 1.03]
        else
            m.tiles[i].grupo.scale = [1, 1]
        end if
    end for
    pintarBotao(m.btnListas, f = "listas")
    pintarBotao(m.btnSair, f = "sair")
end sub

sub irPara(alvo as String)
    m.foco = alvo
    if Left(alvo, 1) = "t" and Len(alvo) = 2 then m.ultimoTile = Int(Val(Mid(alvo, 2)))
    aplicarFoco()
end sub

function irAoTile() as String
    return "t" + Str(m.ultimoTile).Trim()
end function

sub abrirTile(i as Integer)
    if i = 0 then
        uiAcao("abrir", { tela: "Live", args: {} })
    else if i = 1 then
        uiAcao("abrir", { tela: "Catalogo", args: { tipo: "filmes" } })
    else
        uiAcao("abrir", { tela: "Catalogo", args: { tipo: "series" } })
    end if
end sub
' OK no banner de destaques. Os títulos vêm da VPS e o código (id) deles pode ser de outro painel: abrir direto
' mostrava OUTRA série/filme. Por isso o título é procurado pelo nome no painel desta conta e abre o item de lá.
sub aoDestaque()
    if m.slides.Count() = 0 or m.abrindo = true then return
    s = m.slides[m.pos]
    s0 = sessaoLer()
    ' só espera pelo índice se ele já estiver pronto; senão abre na hora (nunca trava o ASSISTIR)
    if s.daVps = true and s.resolvido <> true and s0 <> invalid and s0.modo <> "m3u" and m.idxEst[sv(s.tipo)] = "pronto" then
        m.abrindo = true
        m.bnMeta.text = tx("ABRINDO...")
        m.bnEstrela.visible = false
        m.bnMeta.translation = [m.bnEsq, m.bnMetaY]
        comIndice(sv(s.tipo), { acao: "banner", nome: sv(s.nomeBruto), pos: m.pos })
        return
    end if
    abrirDetalheSlide(s)
end sub

sub abrirDetalheSlide(s as Object)
    uiAcao("abrir", { tela: "Detalhe", args: { tipo: sv(s.tipo), id: sv(s.id), nome: sv(s.nomeBruto), capa: sv(s.capa), ext: sv(s.extPainel), cat: sv(s.cat) } })
end sub

sub fimBannerAchou(pedido as Object, r as Object)
    m.abrindo = false
    mostrarSlide()
    if pedido.pos >= m.slides.Count() then return
    s = m.slides[pedido.pos]
    if sv(s.nomeBruto) <> sv(pedido.nome) then return   ' a lista de destaques mudou enquanto procurava
    if r.ok <> true then
        if r.semIndice = true then
            abrirDetalheSlide(s)   ' sem o índice do painel: abre como antes
        else
            avisoBanner(tx("Este título não está disponível no seu servidor"))
        end if
        return
    end if
    s.id = sv(r.id)
    s.cat = sv(r.cat)
    s.extPainel = sv(r.ext)
    s.resolvido = true
    if pedido.pos <> m.pos then return
    abrirDetalheSlide(s)
end sub

sub avisoBanner(texto as String)
    m.bnEstrela.visible = false
    m.bnMeta.translation = [m.bnEsq, m.bnMetaY]
    m.bnMeta.text = texto
    m.tAvisoBn.control = "stop"
    m.tAvisoBn.control = "start"
end sub

sub fimAvisoBanner()
    if m.slides.Count() > 0 then mostrarSlide()
end sub

sub sairConta()
    uiAcao("sair", invalid)
end sub

function onKeyEvent(tecla as String, pressionou as Boolean) as Boolean
    if not pressionou then return false
    f = m.foco
    temBanner = (m.slides.Count() > 0)
    temDs = m.dsMostrando

    if tecla = "options" then
        uiAcao("abrir", { tela: "Ajustes", args: {} })
        return true
    end if

    if tecla = "OK" then
        if f = "gear" then
            uiAcao("abrir", { tela: "Ajustes", args: {} })
        else if f = "banner" then
            aoDestaque()
        else if f = "ds" then
            aoDestaqueSemana()
        else if f = "listas" then
            uiAcao("abrir", { tela: "Listas", args: {} })
        else if f = "sair" then
            uiConfirmar("Deseja sair?", "A lista que está em uso será removida desta TV.", "Sair", "Cancelar", sairConta)
        else
            abrirTile(m.ultimoTile)
        end if
        return true
    end if

    if Left(f, 1) = "t" and Len(f) = 2 then
        if tecla = "left" then
            if m.ultimoTile > 0 then irPara("t" + Str(m.ultimoTile - 1).Trim())
            return true
        else if tecla = "right" then
            if m.ultimoTile < 2 then irPara("t" + Str(m.ultimoTile + 1).Trim())
            return true
        else if tecla = "up" then
            ' o Destaque da semana fica em cima do cartão da direita (Séries)
            if temDs and m.ultimoTile = 2 then
                irPara("ds")
            else if temBanner then
                irPara("banner")
            else if temDs then
                irPara("ds")
            else
                irPara("gear")
            end if
            return true
        else if tecla = "down" then
            irPara("listas")
            return true
        end if
    else if f = "banner" then
        if tecla = "left" then
            mover(-1)
            return true
        else if tecla = "right" then
            if temDs then irPara("ds") else mover(1)
            return true
        else if tecla = "up" then
            irPara("gear")
            return true
        else if tecla = "down" then
            irPara(irAoTile())
            return true
        end if
    else if f = "ds" then
        if tecla = "left" then
            if temBanner then irPara("banner")
            return true
        else if tecla = "up" then
            irPara("gear")
            return true
        else if tecla = "down" then
            if m.ultimoTile <> 2 then m.ultimoTile = 2
            irPara("t2")
            return true
        else if tecla = "right" then
            return true
        end if
    else if f = "gear" then
        if tecla = "down" then
            if temBanner then
                irPara("banner")
            else if temDs then
                irPara("ds")
            else
                irPara(irAoTile())
            end if
            return true
        end if
        if tecla = "left" or tecla = "right" or tecla = "up" then return true
    else if f = "listas" then
        if tecla = "up" then
            irPara(irAoTile())
            return true
        else if tecla = "right" then
            irPara("sair")
            return true
        else if tecla = "left" or tecla = "down" then
            return true
        end if
    else if f = "sair" then
        if tecla = "up" then
            irPara(irAoTile())
            return true
        else if tecla = "left" then
            irPara("listas")
            return true
        else if tecla = "right" or tecla = "down" then
            return true
        end if
    end if
    return false
end function

sub focar()
    aplicarFoco()
    m.top.setFocus(true)
end sub

' ══ Índice de títulos do painel (banner, destaque e pesquisa) ═══════
' O banner e o Destaque da semana procuram o título pelo nome no painel da conta. Isso usa o índice
' (arquivo guardado na TV). Aqui ele é preparado uma vez, em segundo plano, e os pedidos esperam por ele.
sub iniciarIndicesHome()
    if cfg().preAquecer <> true then return   ' pré-carga em segundo plano desligada (config.json: "preAquecer": true liga)
    s = sessaoLer()
    if s = invalid then return
    if s.modo = "m3u" then return
    comIndice("filmes", { acao: "so" })
end sub

sub comIndice(tipo as String, pedido as Object)
    est = m.idxEst[tipo]
    if est = "pronto" or est = "erro" then
        rodarAcaoIndice(tipo, pedido)
        return
    end if
    m.idxEsp[tipo].Push(pedido)
    if est = "" then
        m.idxEst[tipo] = "rodando"
        t = chamar("IndexTask", "preparar", { tipo: tipo }, "aoIndiceHome")
        m.idxTask[t.id] = tipo
    end if
end sub

sub aoIndiceHome(ev as Object)
    n = ev.getRoSGNode()
    chamarFim(ev)
    r = ev.getData()
    tipo = m.idxTask[n.id]
    m.idxTask.Delete(n.id)
    if tipo = invalid then return
    if r.ok = true then m.idxEst[tipo] = "pronto" else m.idxEst[tipo] = "erro"
    fila = m.idxEsp[tipo]
    m.idxEsp[tipo] = []
    for each p in fila
        rodarAcaoIndice(tipo, p)
    end for
    ' depois dos filmes, prepara o das séries (um de cada vez, para não pesar na rede)
    if tipo = "filmes" and m.idxEst.series = "" then comIndice("series", { acao: "so" })
end sub

sub rodarAcaoIndice(tipo as String, pedido as Object)
    if pedido.acao = "so" then return
    t = chamar("IndexTask", "achar", { tipo: tipo, nome: sv(pedido.nome) }, "aoAchou")
    m.achaMap[t.id] = pedido
end sub

sub aoAchou(ev as Object)
    n = ev.getRoSGNode()
    chamarFim(ev)
    r = ev.getData()
    pedido = m.achaMap[n.id]
    m.achaMap.Delete(n.id)
    if pedido = invalid then return
    if pedido.acao = "banner" then
        fimBannerAchou(pedido, r)
    else if pedido.acao = "destaque" then
        fimDestaqueAchou(pedido, r)
    end if
end sub

' ══ Painel: confere de tempos em tempos se o Destaque da semana mudou ═
sub tiqueVisual()
    if not m.top.visible then return   ' outra tela está por cima da Home
    chamar("AuthTask", "visual", {}, "aoVisualHome")
end sub

sub aoVisualHome(ev as Object)
    chamarFim(ev)
    r = ev.getData()
    if r = invalid then return
    if not isAA(r) then return
    if r.Count() = 0 then return   ' sem resposta do painel: continua com o que já tinha
    m.global.visual = r
    aplicarVisual()
end sub

' ══ Destaque da semana ═══════════════════════════════════════════════
' Quem manda é o painel (campos destaque_ativo, destaque_tipo, destaque_nome, destaque_tmdb, destaque_imagem e
' destaque_sinopse em /lg/config). Só o NOME do título é enviado: a TV procura o título no painel da conta
' (com o id certo) e abre os detalhes. Se a conta não tem o título, o destaque simplesmente não aparece.
function verdadeiro(v as Dynamic) as Boolean
    t = LCase(sv(v))
    return (t = "true" or t = "1")
end function

function tipoDestaque(t as String) as String
    x = LCase(t)
    if x = "series" or x = "serie" or x = "série" or x = "séries" then return "series"
    return "filmes"
end function

function configDestaque() as Object
    c = { ativo: false, tipo: "filmes", nome: "", imagem: "", tmdb: "", sinopse: "" }
    achou = false
    v = m.global.visual
    if v <> invalid then
        if isAA(v) then
            if v.destaque_ativo <> invalid then
                achou = true
                c.ativo = verdadeiro(v.destaque_ativo)
                c.tipo = tipoDestaque(sv(v.destaque_tipo))
                c.nome = sv(v.destaque_nome)
                c.imagem = sv(v.destaque_imagem)
                c.tmdb = sv(v.destaque_tmdb)
                c.sinopse = sv(v.destaque_sinopse)
                txt = FormatJson(c)
                if regGet("destaque_cfg") <> txt then regSet("destaque_cfg", txt)
            end if
        end if
    end if
    if not achou then
        ' o painel não respondeu: vale a última configuração que ele mandou
        g = regJson("destaque_cfg")
        if g <> invalid then
            if isAA(g) then
                c.ativo = (g.ativo = true)
                c.tipo = tipoDestaque(sv(g.tipo))
                c.nome = sv(g.nome)
                c.imagem = sv(g.imagem)
                c.tmdb = sv(g.tmdb)
                c.sinopse = sv(g.sinopse)
            end if
        end if
    end if
    c.nome = c.nome.Trim()
    c.tmdb = CreateObject("roRegex", "[^0-9]", "").ReplaceAll(c.tmdb, "")
    c.sinopse = CreateObject("roRegex", "\s+", "").ReplaceAll(c.sinopse, " ").Trim()
    if Len(c.sinopse) > 500 then c.sinopse = Left(c.sinopse, 500)
    img = c.imagem.Trim()
    if Left(img, 1) = "/" then img = sv(cfg().licenca) + img
    if LCase(Left(img, 4)) <> "http" then img = ""
    c.imagem = img
    c.ativo = (c.ativo and c.nome <> "")
    return c
end function

sub atualizarDestaque()
    c = configDestaque()
    if not c.ativo then
        esconderDestaque()
        return
    end if
    s0 = sessaoLer()
    if s0 = invalid then return
    if s0.modo = "m3u" then
        esconderDestaque()   ' lista M3U não tem índice do painel
        return
    end if
    chave = c.tipo + "|" + c.nome + "|" + c.tmdb + "|" + c.imagem + "|" + c.sinopse + "|" + donoConta()
    ' já está na tela (ou sendo procurado) com esta configuração: nada a fazer
    if m.dsChave = chave and (m.dsMostrando or m.dsBuscando) then return
    ' não achou este título há pouco: não procura de novo a cada minuto
    if m.dsFalhou = chave and nowSec() - m.dsFalhouT < 600 then return
    m.dsChave = chave
    m.dsCfg = c
    ' O último destaque fica guardado na TV: da segunda vez em diante a Home já abre no layout certo.
    g = lerJsonArq(caminhoCache("destaque.json"))
    if g <> invalid then
        if isAA(g) then
            if sv(g.chave) = chave and isAA(g.item) then
                m.ds = g.item
                mostrarDestaqueNaTela()
                if nowSec() - iv(g.t) < 43200 then return   ' ainda novo: não precisa conferir de novo
            end if
        end if
    end if
    m.dsBuscando = true
    m.dsGer = m.dsGer + 1
    comIndice(c.tipo, { acao: "destaque", nome: c.nome, ger: m.dsGer })
end sub

sub esconderDestaque()
    m.dsGer = m.dsGer + 1
    m.dsBuscando = false
    m.dsMostrando = false
    m.dsChave = ""
    m.ds = invalid
    m.dsG.visible = false
    m.dsFoco.visible = false
    if m.bnComDs then ajustarBanner(false)
    if m.foco = "ds" then
        if m.slides.Count() > 0 then m.foco = "banner" else m.foco = irAoTile()
    end if
    aplicarFoco()
end sub

sub fimDestaqueAchou(pedido as Object, r as Object)
    if pedido.ger <> m.dsGer then return   ' a configuração mudou enquanto procurava
    if r.ok <> true then
        ' a conta não tem este título: o destaque não aparece
        chave = m.dsChave
        arqApagar(caminhoCache("destaque.json"))
        esconderDestaque()
        m.dsFalhou = chave
        m.dsFalhouT = nowSec()
        return
    end if
    m.dsAchou = r
    t = chamar("TmdbTask", "destaque", { tipo: m.dsCfg.tipo, tmdb: m.dsCfg.tmdb, nome: sv(r.nome) }, "aoDsTmdb")
    m.dsMap[t.id] = pedido.ger
end sub

sub aoDsTmdb(ev as Object)
    n = ev.getRoSGNode()
    chamarFim(ev)
    ger = m.dsMap[n.id]
    m.dsMap.Delete(n.id)
    if ger = invalid then return
    if ger <> m.dsGer then return
    t = ev.getData()
    c = m.dsCfg
    a = m.dsAchou
    b = analisarTitulo(sv(a.nome))
    item = { tipo: c.tipo, id: sv(a.id), nomeBruto: sv(a.nome), cat: sv(a.cat), ext: sv(a.ext), nome: limparTitulo(sv(a.nome)), nomeEn: "", capa: "", logo: "", fundo: "", sinopse: c.sinopse, nota: uiNota(a.rating), ano: sv(b.ano) }
    if t.ok = true then
        item.logo = sv(t.logo)
        item.fundo = sv(t.fundo)
        item.capa = sv(t.capa)
        if idiomaEn() and sv(t.titulo) <> "" then item.nomeEn = sv(t.titulo)
        if item.sinopse = "" then item.sinopse = sv(t.sinopse)
        if item.nota = "" then item.nota = sv(t.nota)
    end if
    ' sem fundo do TMDB: vale a imagem própria mandada pelo painel
    if item.fundo = "" then item.fundo = c.imagem
    m.ds = item
    m.dsBuscando = false
    gravarJsonArq(caminhoCache("destaque.json"), { chave: m.dsChave, t: nowSec(), item: item })
    mostrarDestaqueNaTela()
end sub

sub mostrarDestaqueNaTela()
    if m.ds = invalid then return
    m.dsMostrando = true
    m.dsG.visible = true
    if not m.bnComDs then ajustarBanner(true)
    pintarDestaque()
    aplicarFoco()
end sub

sub pintarDestaque()
    s = m.ds
    if sv(s.fundo) <> "" then
        m.dsFundo.blendColor = "0xFFFFFFFF"
        m.dsFundo.uri = sv(s.fundo)
    else if sv(s.capa) <> "" then
        m.dsFundo.blendColor = "0xB8B8B8FF"
        m.dsFundo.uri = sv(s.capa)
    else
        m.dsFundo.uri = ""
    end if
    nome = sv(s.nome)
    if idiomaEn() and sv(s.nomeEn) <> "" then nome = sv(s.nomeEn)
    m.dsTit.text = nome
    m.dsHLogo = 0
    logo = sv(s.logo)
    if logo <> "" then
        m.dsTit.visible = false
        m.dsLogo.visible = false
        if m.dsLogo.uri = logo then
            aoDsLogoCarregou()
        else
            m.dsLogo.uri = logo
        end if
    else
        m.dsLogo.uri = ""
        m.dsLogo.visible = false
        m.dsTit.visible = true
    end if
    meta = ""
    m.dsEstrela.visible = false
    m.dsMetaX = 48
    if sv(s.nota) <> "" then
        meta = sv(s.nota)
        m.dsEstrela.visible = true
        m.dsMetaX = 48 + 32
    end if
    if sv(s.ano) <> "" then
        if meta <> "" then meta = meta + "   •   "
        meta = meta + sv(s.ano)
    end if
    if meta <> "" then meta = meta + "   •   "
    if sv(s.tipo) = "series" then
        meta = meta + tx("Série")
    else
        meta = meta + tx("Filme")
    end if
    m.dsMeta.text = meta
    m.dsSin.text = sv(s.sinopse)
    layoutDestaque()
end sub

' Empilha de baixo para cima (como o CSS da LG): botão, sinopse, dados, título ou logo, e "DESTAQUE DA SEMANA" em cima.
sub layoutDestaque()
    x = 48
    cur = 400 - 22
    if sv(m.dsSin.text) <> "" then
        h = 87
        r = m.dsSin.boundingRect()
        if r <> invalid then
            if r.height > 0 and r.height < 87 then h = Int(r.height + 0.5)
        end if
        m.dsSin.translation = [x, cur - h]
        m.dsSin.visible = true
        cur = cur - h - 12
    else
        m.dsSin.visible = false
    end if
    cur = cur - 30
    m.dsMeta.translation = [m.dsMetaX, cur]
    m.dsEstrela.translation = [x, cur + 3]
    cur = cur - 12
    hv = 130
    if m.dsLogo.visible then
        hv = m.dsHLogo
    else
        r = m.dsTit.boundingRect()
        if r <> invalid then
            if r.height > 0 and r.height < 130 then hv = Int(r.height + 0.5)
        end if
    end if
    m.dsTit.translation = [x, cur - 130]
    m.dsLogo.translation = [x, cur - m.dsHLogo]
    m.dsEtq.translation = [x, cur - hv - 14 - 30]
end sub

sub aoDsFundoCarregou()
    if m.dsFundo.loadStatus <> "ready" then return
    bw = m.dsFundo.bitmapWidth
    bh = m.dsFundo.bitmapHeight
    if bw <= 0 or bh <= 0 then return
    e = 668 / bw
    e2 = 502 / bh
    if e2 > e then e = e2
    w = bw * e
    h = bh * e
    m.dsFundo.width = w
    m.dsFundo.height = h
    m.dsFundo.translation = [(668 - w) / 2, 0]
end sub

sub aoDsLogoCarregou()
    st = m.dsLogo.loadStatus
    if st = "failed" then
        m.dsLogo.visible = false
        m.dsHLogo = 0
        m.dsTit.visible = true
        layoutDestaque()
        return
    end if
    if st <> "ready" then return
    bw = m.dsLogo.bitmapWidth
    bh = m.dsLogo.bitmapHeight
    if bw <= 0 or bh <= 0 then return
    e = 1.0
    if bw * e > 520 then e = 520 / bw
    if bh * e > 130 then e = 130 / bh
    w = Int(bw * e)
    h = Int(bh * e)
    m.dsLogo.width = w
    m.dsLogo.height = h
    m.dsHLogo = h
    m.dsLogo.visible = true
    m.dsTit.visible = false
    layoutDestaque()
end sub

sub aoDestaqueSemana()
    s = m.ds
    if s = invalid then return
    uiAcao("abrir", { tela: "Detalhe", args: { tipo: sv(s.tipo), id: sv(s.id), nome: sv(s.nomeBruto), capa: sv(s.capa), ext: sv(s.ext), cat: sv(s.cat) } })
end sub

' Deixa Filmes, Séries e TV ao vivo prontos antes de o usuário entrar (como na LG): baixa e guarda na TV as categorias
' e as primeiras listas. Ao abrir, a tela já nasce cheia. Só uma vez por abertura do app.
sub aquecerCatalogo()
    if cfg().preAquecer <> true then return   ' pré-carga em segundo plano desligada (config.json: "preAquecer": true liga)
    if m.aquecido = true then return
    s = sessaoLer()
    if s = invalid then return
    if s.modo = "m3u" then return
    m.aquecido = true
    chamar("ApiTask", "aquecer", { tipos: ["filmes", "series", "ao_vivo"] }, "aoAquecido")
end sub

sub aoAquecido(ev as Object)
    chamarFim(ev)
end sub
