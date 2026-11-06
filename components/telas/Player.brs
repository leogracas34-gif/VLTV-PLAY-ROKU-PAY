' VLTV Play - Roku | Player em tela cheia: TV ao vivo (troca de canal, m3u8 -> ts), filmes e séries (continuar de onde parou,
' próximo episódio, créditos aprendidos, áudio e legenda).

sub iniciar()
    try
        iniciarReal()
    catch e
        print "[ERRO] Player.iniciar: "; sv(e.message); " #"; sv(e.number)
        uiAcao("erro", { texto: tx("Não foi possível reproduzir. Tente outro título ou canal.") })
    end try
end sub

sub iniciarReal()
    carregarI18n()
    a = m.top.args
    m.tipo = sv(a.tipo)
    m.reg = a.reg
    m.chave = sv(a.chave)
    m.serie = sv(a.serie)
    m.credSeg = 0
    m.fi = 0
    m.tent = 0
    m.fim = false
    m.sairFeito = false

    ' Sem retângulo preto atrás do Video: nada opaco pode ficar entre o vídeo e a tela, senão a imagem some.
    m.video = uiNo(m.top, "Video", { translation: [0, 0], width: 1920, height: 1080, enableUI: false, enableTrickPlay: false })
    ' O Video da Roku puxa o foco para si ao começar a tocar e engole voltar/pausar.
    ' Com focusable=false ele nunca fica com o controle: o foco fica aqui no Player (m.top) e as teclas chegam no onKeyEvent.
    m.video.setField("focusable", false)
    m.video.observeField("state", "aoEstado")

    ' controles (iguais aos da LG): degradê, título, barra de 18px e tempos
    m.barra = uiNo(m.top, "Group", { visible: false })
    uiNo(m.barra, "Poster", { translation: [0, 720], width: 1920, height: 360, uri: "pkg:/images/ui/grad_ctrl.png", loadDisplayMode: "scaleToFill" })
    m.titulo = vkTxt(m.barra, 100, 860, 1720, 51, "", 44, true, cBranco(), "left")
    m.sub1 = vkTxt(m.barra, 100, 914, 1720, 36, "", 28, false, cSuave(), "left")
    m.barraBg = vkNine(m.barra, 100, 958, 1720, 18, "f9")
    m.barraBg.blendColor = "0xFFFFFF40"
    m.progresso = vkRet(m.barra, 100, 958, 1, 18, cClaro())
    m.tTempo = vkTxt(m.barra, 100, 992, 400, 32, "", 28, false, cSuave(), "left")
    m.tEstado = vkTxt(m.barra, 700, 992, 520, 32, "", 28, false, cSuave(), "center")
    m.tDur = vkTxt(m.barra, 1420, 992, 400, 32, "", 28, false, cSuave(), "right")

    ' aviso (toast no topo)
    m.avisoGr = uiNo(m.top, "Group", { visible: false })
    m.avisoBg = vkNine(m.avisoGr, 510, 70, 900, 80, "f14")
    m.avisoBg.blendColor = "0x000000C7"
    m.aviso = vkTxtM(m.avisoGr, 538, 88, 844, 44, "", 30, true, cBranco(), 3, "center")
    m.carregando = vkTxt(m.top, 0, 500, 1920, 80, tx("Carregando..."), 44, false, cBranco(), "center")

    ' Próximo episódio (estilo Netflix) com contagem regressiva
    m.btProx = uiNo(m.top, "Group", { visible: false })
    m.ppTemp = vkTxt(m.btProx, 1180, 600, 640, 34, "", 26, true, cNota(), "right")
    m.ppConta = vkTxt(m.btProx, 1180, 636, 640, 40, "", 30, true, cBranco(), "right")
    m.ppCx = vkCaixa(m.btProx, 1180, 686, 640, 112, 20, 4, 6)
    vkPintar(m.ppCx, cBranco(), "0x141416EB", false)
    m.ppFill = vkRet(m.btProx, 1184, 690, 1, 104, "0xB20710FF")
    vkImg(m.btProx, 1214, 716, 52, 52, "i_proximo", cBranco())
    vkTxt(m.btProx, 1288, 696, 520, 48, tx("Próximo episódio"), 36, true, cBranco(), "left")
    m.ppTitulo = vkTxt(m.btProx, 1288, 742, 520, 34, "", 24, false, "0xFFFFFFD1", "left")
    vkTxt(m.btProx, 1180, 806, 640, 30, tx("Aperte OK para assistir agora"), 22, false, "0xFFFFFFB3", "right")

    m.escondeBarra = uiNo(m.top, "Timer", { repeat: false, duration: 5 })
    m.escondeBarra.observeField("fire", "esconderBarra")
    m.guarda = uiNo(m.top, "Timer", { repeat: true, duration: 15 })
    m.guarda.observeField("fire", "salvar")
    m.guarda.control = "start"
    m.relogio = uiNo(m.top, "Timer", { repeat: true, duration: 1 })
    m.relogio.observeField("fire", "tique")
    m.relogio.control = "start"
    ' canal ao vivo em .ts que não começa a tocar em 12 s: cai para o .m3u8
    m.tFallback = uiNo(m.top, "Timer", { repeat: false, duration: 12 })
    m.tFallback.observeField("fire", "aoDemoraTs")

    if m.tipo = "live" then
        m.lista = a.lista
        m.i = iv(a.indice)
        tocarCanal()
    else
        if m.tipo = "filme" then
            m.fila = [{ id: "", url: sv(a.url), titulo: sv(a.titulo) }]
        else
            m.fila = a.fila
            if m.serie <> "" then chamar("ApiTask", "creditos_buscar", { serie: m.serie }, "aoCreditos")
        end if
        tocar(iv(a.pos))
    end if
    garantirFocoPlayer()
end sub

sub retomar()
    garantirFocoPlayer()
end sub

sub encerrar()
    try
        salvar()
    catch e
        print "[player] erro ao salvar: "; e.message
    end try
    m.tFallback.control = "stop"
    m.guarda.control = "stop"
    m.relogio.control = "stop"
    m.video.control = "stop"
end sub

' ── Tocar ───────────────────────────────────────────────────────────
function formatoDe(url as String) as String
    u = LCase(url)
    q = Instr(1, u, "?")
    if q > 0 then u = Left(u, q - 1)
    if endsWith(u, ".m3u8") then return "hls"
    if endsWith(u, ".mkv") then return "mkv"
    if endsWith(u, ".mp4") or endsWith(u, ".m4v") or endsWith(u, ".mov") then return "mp4"
    if endsWith(u, ".ts") then return "ts"
    return ""
end function

sub iniciarVideo(url as String, formato as String, titulo as String, posicao as Integer)
    m.avisoGr.visible = false
    m.carregando.visible = true
    m.fmtAtual = formato
    m.urlAtual = url
    cn = CreateObject("roSGNode", "ContentNode")
    cn.url = url
    cn.title = titulo
    if formato <> "" then cn.streamFormat = formato
    if posicao > 0 then cn.playStart = posicao
    m.video.content = cn
    m.video.control = "play"
    garantirFocoPlayer()
    logarEstado()
end sub

sub tocar(posicao as Integer)
    item = m.fila[m.fi]
    m.fim = false
    m.titulo.text = sv(item.titulo)
    if m.tipo = "episodio" then
        m.chave = "ep:" + sv(item.id)
        m.titulo.text = sv(m.top.args.titulo)
        m.sub1.text = sv(item.titulo)
    else
        m.sub1.text = ""
    end if
    m.btProx.visible = false
    iniciarVideo(sv(item.url), formatoDe(sv(item.url)), sv(item.titulo), posicao)
    mostrarBarra()
end sub

function urlLive(c as Object, ext as String) as String
    s = sessaoLer()
    if s = invalid then return ""
    if s.modo = "m3u" then return sv(c.url)
    return urlStream(s, "live", sv(c.id), ext)
end function

' Canal ao vivo: primeiro m3u8 (HLS); se falhar, tenta .ts.
sub tocarCanal()
    c = m.lista[m.i]
    m.tent = 0
    m.titulo.text = sv(c.nome)
    m.sub1.text = tx("Canal") + " " + Str(m.i + 1).Trim() + " / " + Str(m.lista.Count()).Trim()
    tentarCanal()
    mostrarBarra()
    chamar("ApiTask", "epg", { id: sv(c.id), limite: 2 }, "aoEpgCanal")
end sub

sub tentarCanal()
    c = m.lista[m.i]
    s = sessaoLer()
    if s = invalid then return
    m.tFallback.control = "stop"
    if s.modo = "m3u" then
        u = sv(c.url)
        f = formatoDe(u)
        if m.tent = 1 then
            if f = "hls" then f = "ts" else f = "hls"
        end if
        iniciarVideo(u, f, sv(c.nome), 0)
    else
        f = liveFmtPreferido()
        if m.tent = 1 then f = liveFmtOutro(f)
        if f = "ts" then
            iniciarVideo(urlLive(c, "ts"), "ts", sv(c.nome), 0)
            if m.tent = 0 then m.tFallback.control = "start"
        else
            iniciarVideo(urlLive(c, "m3u8"), "hls", sv(c.nome), 0)
        end if
    end if
end sub

sub aoDemoraTs()
    if m.tipo <> "live" or m.tent <> 0 then return
    if m.video.state = "playing" then return
    liveTsFalhou()
    m.tent = 1
    tentarCanal()
end sub

sub aoEpgCanal(ev as Object)
    chamarFim(ev)
    r = ev.getData()
    if r.ok <> true then return
    sep = separarEpg(r.lista, nowSec())
    if sep.atual <> invalid and m.tipo = "live" then
        m.sub1.text = sv(sep.atual.inicio) + " " + sv(sep.atual.titulo) + "     " + tx("Canal") + " " + Str(m.i + 1).Trim() + " / " + Str(m.lista.Count()).Trim()
    end if
end sub

sub aoCreditos(ev as Object)
    chamarFim(ev)
    r = ev.getData()
    if r.ok = true then m.credSeg = iv(r.seg)
end sub

' ── Estado do vídeo ─────────────────────────────────────────────────
sub logarEstado()
    v = m.video
    t = "estado=" + sv(v.state)
    if v.errorCode <> invalid then t = t + " erro=" + Str(v.errorCode).Trim() + " " + sv(v.errorMsg)
    t = t + " fmt=" + sv(m.fmtAtual) + " " + sv(m.urlAtual)
    print "[player] "; t
end sub

sub aoEstado(ev as Object)
    est = ev.getData()
    logarEstado()
    garantirFocoPlayer()
    if est = "playing" then
        m.carregando.visible = false
        m.avisoGr.visible = false
        m.tFallback.control = "stop"
        if m.tipo = "live" and m.tent = 0 and m.fmtAtual = "ts" then liveTsFuncionou()
        m.tent = 0
        if m.tipo = "live" then m.tentouTs = false
    else if est = "buffering" then
        m.carregando.visible = true
    else if est = "paused" then
        mostrarBarra()
    else if est = "finished" then
        terminou()
    else if est = "error" then
        falhou()
    end if
end sub

sub falhou()
    m.carregando.visible = false
    m.tFallback.control = "stop"
    if m.tipo = "live" and m.tent = 0 then
        if m.fmtAtual = "ts" then liveTsFalhou()
        m.tent = 1
        tentarCanal()
        return
    end if
    codigo = m.video.errorCode
    txt = "Não foi possível reproduzir. Tente outro título ou canal."
    if m.tipo <> "live" then
        u = LCase(sv(m.fila[m.fi].url))
        if endsWith(u, ".avi") or endsWith(u, ".wmv") or endsWith(u, ".flv") or endsWith(u, ".mpg") then
            txt = "Este formato de vídeo não é aceito pela Roku."
        end if
    end if
    if codigo = -3 or codigo = -5 then txt = "Sem conexão com o servidor. Confira a internet."
    m.aviso.text = tx(txt)
    m.avisoGr.visible = true
end sub

sub terminou()
    if m.tipo = "live" then
        tocarCanal()
        return
    end if
    m.fim = true
    salvar()
    if m.tipo = "episodio" and m.fi + 1 < m.fila.Count() then
        m.fi = m.fi + 1
        tocar(0)
    else
        sair()
    end if
end sub

sub sair()
    if m.sairFeito then return
    m.sairFeito = true
    uiAcao("voltar", invalid)
end sub

' ── Progresso ───────────────────────────────────────────────────────
' Qualquer erro ao salvar o progresso é ignorado: nunca pode travar o voltar, o pause ou o timer de 15 s.
sub salvar()
    try
        salvarReal()
    catch e
        print "[player] erro ao salvar progresso: "; e.message
    end try
end sub

sub salvarReal()
    if m.tipo = "live" or m.chave = "" or m.reg = invalid then return
    dur = Int(m.video.duration)
    posicao = Int(m.video.position)
    if m.fim then posicao = dur
    if dur <= 0 then return
    r = {}
    r.Append(m.reg)
    r.pos = posicao
    r.dur = dur
    r.t = nowSec()
    if m.tipo = "episodio" then r.ep = sv(m.fila[m.fi].titulo)
    progressoSalvar(m.chave, r)
end sub

sub tique()
    garantirFocoPlayer()
    if m.video.state <> "playing" and m.video.state <> "paused" then return
    dur = m.video.duration
    posicao = m.video.position
    if m.barra.visible and m.tipo <> "live" and dur > 0 then
        m.progresso.width = Int(1720 * posicao / dur)
        if m.progresso.width < 1 then m.progresso.width = 1
        m.tTempo.text = hms(posicao)
        m.tDur.text = hms(dur)
    end if
    if m.barra.visible then
        if m.video.state = "paused" then m.tEstado.text = tx("Pausado") else m.tEstado.text = ""
    end if
    ' cartão do próximo episódio
    if m.tipo = "episodio" and m.fi + 1 < m.fila.Count() and dur > 0 then
        resta = dur - posicao
        limite = 45
        if m.credSeg > 0 then limite = m.credSeg
        mostrar = (resta <= limite and posicao > 60)
        if mostrar then
            prox = m.fila[m.fi + 1]
            m.ppTitulo.text = sv(prox.titulo)
            n = Int(resta) + 1
            m.ppConta.text = tx("Próximo episódio em") + " " + Str(n).Trim() + "s"
            frac = 1 - resta / limite
            if frac < 0 then frac = 0
            if frac > 1 then frac = 1
            m.ppFill.width = Int(632 * frac) + 1
        end if
        m.btProx.visible = mostrar
    end if
end sub

sub mostrarBarra()
    m.barra.visible = true
    m.escondeBarra.control = "stop"
    m.escondeBarra.control = "start"
    tique()
end sub

sub esconderBarra()
    if m.video.state = "paused" then return
    m.barra.visible = false
end sub

' ── Teclas ──────────────────────────────────────────────────────────
sub proximo(aprender as Boolean)
    if m.tipo <> "episodio" or m.fi + 1 >= m.fila.Count() then return
    resta = Int(m.video.duration - m.video.position)
    if aprender and m.serie <> "" and resta >= 5 and resta <= 600 and m.video.position > 60 then
        chamar("ApiTask", "creditos_enviar", { serie: m.serie, seg: resta }, "aoCreditosEnviados")
        m.credSeg = resta
    end if
    salvar()
    m.fi = m.fi + 1
    tocar(0)
end sub

sub aoCreditosEnviados(ev as Object)
    chamarFim(ev)
end sub

sub pular(seg as Integer)
    if m.tipo = "live" then return
    novo = m.video.position + seg
    if novo < 0 then novo = 0
    if m.video.duration > 0 and novo > m.video.duration - 3 then novo = m.video.duration - 3
    m.video.seek = novo
    mostrarBarra()
end sub

function onKeyEvent(tecla as String, pressionou as Boolean) as Boolean
    if not pressionou then return false
    if tecla = "back" then
        print "[player] tecla voltar recebida"
        sair()
        return true
    else if tecla = "OK" and m.btProx.visible then
        proximo(true)
        return true
    else if tecla = "OK" or tecla = "play" then
        if m.tipo = "live" then
            mostrarBarra()
        else if m.video.state = "paused" then
            m.video.control = "resume"
            mostrarBarra()
        else
            m.video.control = "pause"
        end if
        return true
    else if tecla = "left" then
        pular(-10)
        return true
    else if tecla = "right" then
        pular(10)
        return true
    else if tecla = "rewind" then
        pular(-60)
        return true
    else if tecla = "fastforward" then
        pular(60)
        return true
    else if tecla = "replay" then
        pular(-10)
        return true
    else if tecla = "up" then
        if m.tipo = "live" then
            trocarCanal(-1)
        else
            mostrarBarra()
        end if
        return true
    else if tecla = "down" then
        if m.tipo = "live" then
            trocarCanal(1)
        else if m.btProx.visible then
            proximo(true)
        else
            mostrarBarra()
        end if
        return true
    else if tecla = "options" then
        abrirMenu()
        return true
    end if
    return false
end function

sub trocarCanal(d as Integer)
    n = m.lista.Count()
    if n < 2 then return
    m.i = (m.i + d + n) mod n
    tocarCanal()
end sub

' ── Opções (áudio, legenda, próximo episódio) ────────────────────────
sub abrirMenu()
    m.menuAcoes = []
    textos = []
    audios = m.video.availableAudioTracks
    if audios <> invalid and audios.Count() > 1 then
        textos.Push(tx("Áudio"))
        m.menuAcoes.Push("audio")
    end if
    legendas = m.video.availableSubtitleTracks
    if legendas <> invalid and legendas.Count() > 0 then
        textos.Push(tx("Legenda"))
        m.menuAcoes.Push("legenda")
    end if
    if m.tipo = "episodio" and m.fi + 1 < m.fila.Count() then
        textos.Push(tx("Próximo episódio"))
        m.menuAcoes.Push("proximo")
    end if
    if textos.Count() = 0 then
        m.aviso.text = tx("Sem faixas de áudio ou legenda neste vídeo.")
        m.avisoGr.visible = true
        m.escondeAviso = uiNo(m.top, "Timer", { repeat: false, duration: 2.5 })
        m.escondeAviso.observeField("fire", "sumirAviso")
        m.escondeAviso.control = "start"
        return
    end if
    uiEscolher("Opções", textos, -1, aoMenu)
end sub

sub sumirAviso()
    m.avisoGr.visible = false
end sub

sub aoMenu(i as Integer)
    acao = m.menuAcoes[i]
    if acao = "audio" then
        m.trilhas = m.video.availableAudioTracks
        nomes = []
        atual = 0
        j = 0
        for each t in m.trilhas
            n = sv(t.Name)
            if n = "" then n = sv(t.Language)
            nomes.Push(n)
            if sv(t.Track) = sv(m.video.audioTrack) then atual = j
            j = j + 1
        end for
        uiEscolher("Áudio", nomes, atual, aoEscolherAudio)
    else if acao = "legenda" then
        m.trilhas = m.video.availableSubtitleTracks
        nomes = [tx("Desligada")]
        for each t in m.trilhas
            n = sv(t.Description)
            if n = "" then n = sv(t.Language)
            nomes.Push(n)
        end for
        uiEscolher("Legenda", nomes, 0, aoEscolherLegenda)
    else if acao = "proximo" then
        proximo(true)
    end if
end sub

sub aoEscolherAudio(i as Integer)
    if i >= 0 and i < m.trilhas.Count() then m.video.audioTrack = sv(m.trilhas[i].Track)
end sub

sub aoEscolherLegenda(i as Integer)
    if i = 0 then
        m.video.globalCaptionMode = "Off"
    else if i - 1 < m.trilhas.Count() then
        m.video.globalCaptionMode = "On"
        m.video.subtitleTrack = sv(m.trilhas[i - 1].TrackName)
    end if
end sub

sub focar()
    garantirFocoPlayer()
end sub

' O foco fica no próprio Player (m.top), nunca no Video. Com uma janela (Opções) aberta, não mexe.
sub garantirFocoPlayer()
    if uiJanelaAberta() then return
    if m.video <> invalid then
        if m.video.isInFocusChain() then m.video.setFocus(false)
    end if
    if not m.top.hasFocus() then m.top.setFocus(true)
end sub
