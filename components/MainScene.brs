' VLTV Play - Roku | Cena principal: pilha de telas, partida do app, licença e login automático.

sub init()
    m.pilha = m.top.findNode("pilha")
    m.telas = []
    m.top.setFocus(true)
    m.top.backgroundURI = ""
    m.top.backgroundColor = "0x0A0A0CFF"
    ' Avisa a Roku que o app abriu (necessário para publicar).
    m.top.signalBeacon("AppLaunchComplete")
    g = m.global
    idioma = regGet("idioma")
    if idioma = "pt-BR" then g.idioma = "pt-BR" else g.idioma = "en"   ' padrão: inglês (igual ao app da LG 1.2.6)
    carregarI18n()
    ' Vigia: em qualquer tela, confere a cada 2 min se a TV foi bloqueada/revogada ou se o código de parceiro caiu.
    m.vigia = CreateObject("roSGNode", "Timer")
    m.vigia.repeat = true
    m.vigia.duration = 120
    m.vigia.observeField("fire", "vigiar")
    m.vigia.control = "start"
    ' Vigia do foco: se por qualquer motivo o controle remoto "soltar" a tela, devolve o foco a ela.
    m.vigiaFoco = CreateObject("roSGNode", "Timer")
    m.vigiaFoco.repeat = true
    m.vigiaFoco.duration = 1
    m.vigiaFoco.observeField("fire", "garantirFoco")
    m.vigiaFoco.control = "start"
    partida()
end sub

' ── Partida ─────────────────────────────────────────────────────────
sub partida()
    s = sessaoLer()
    if s = invalid then
        abrirLogin("")
        return
    end if
    mostrarCarregando("Entrando...")
    autenticarPar(ctxDaSessao(s), partidaEntrar)
end sub

function ctxDaSessao(s as Object) as Object
    return { modo: s.modo, user: sv(s.user), pass: sv(s.pass), codigo: sv(s.codigo), servidor: sv(s.dns), m3u: sv(s.m3u), dnsPreferido: sv(s.dns) }
end function

sub partidaEntrar(r as Object)
    esconderCarregando()
    estado = sv(r.estado)
    s = sessaoLer()
    if estado = "ok" and m.trocando = true then
        ' Troca de lista: entra e avisa a VPS (por trás) se a nova lista é de parceiro (TV ativa) ou não.
        m.trocando = false
        codigo = ""
        if s <> invalid and s.modo = "parceiro" then codigo = UCase(sv(s.codigo))
        entrou(r, codigo)
    else if estado = "ok" or estado = "erro" or estado = "rede" then
        ' Sem rede também abre: o que já está guardado na TV continua aparecendo.
        entrou(r, invalid)
    else if estado = "sem_licenca" then
        if r.lic <> invalid then m.global.lic = r.lic
        abrirAtivacao()
    else if (estado = "codigo_invalido" or estado = "suspenso") and s <> invalid and s.modo = "parceiro" then
        ' Código de parceiro apagado ou suspenso: a TV deixa de ser "parceiro". Sem licença própria, bloqueia e pede a ativação.
        m.trocando = false
        mostrarCarregando("Entrando...")
        chamar("AuthTask", "informar", { codigo: "" }, "aoParceiroCaiu")
    else if estado = "expirado" then
        m.trocando = false
        sessaoLimpar()
        abrirLogin("Essa lista venceu. Fale com o seu provedor ou entre com outra lista.")
    else if estado = "invalido" then
        m.trocando = false
        sessaoLimpar()
        abrirLogin("Usuário ou senha não conferem mais. Entre de novo.")
    else
        m.trocando = false
        abrirLogin("")
    end if
end sub

sub aoParceiroCaiu(ev as Object)
    chamarFim(ev)
    chamar("AuthTask", "licenca", {}, "aoParceiroCaiu2")
end sub

sub aoParceiroCaiu2(ev as Object)
    chamarFim(ev)
    esconderCarregando()
    lic = ev.getData()
    m.global.ehParceiro = false
    m.global.parceiroNome = ""
    sessaoLimpar()
    if sv(lic.estado) = "expired" or sv(lic.estado) = "blocked" then
        m.global.lic = lic
        limparPilha()
        abrir("Ativacao", { msg: "O código de parceiro desta lista não está mais ativo. Para continuar, ative a licença desta TV." })
    else
        abrirLogin("O código de parceiro não está mais ativo. Entre com outra lista.")
    end if
end sub

' Login deu certo (ou app reaberto): guarda dados da conta e abre a Home.
sub entrou(r as Object, informar as Dynamic)
    s = sessaoLer()
    if s = invalid then
        abrirLogin("")
        return
    end if
    g = m.global
    if r.base <> invalid and sv(r.base) <> "" and s.modo <> "usuario" and s.modo <> "m3u" then
        s.dns = sv(r.base)
        sessaoSalvar(s)
    end if
    if r.lic <> invalid then g.lic = r.lic
    if r.info <> invalid then g.info = r.info
    if r.nome <> invalid and sv(r.nome) <> "" then g.parceiroNome = sv(r.nome)
    if s.modo <> "parceiro" then g.parceiroNome = ""
    g.ehParceiro = (s.modo = "parceiro")
    g.parentalLiberado = false
    limparPilha()
    abrir("Home", {})
    chamar("AuthTask", "visual", {}, "visualChegou")
    ' Aviso à VPS por trás (não deixa a Home esperando).
    if informar <> invalid then
        if Type(informar) = "String" or Type(informar) = "roString" then chamar("AuthTask", "informar", { codigo: informar }, "aoInformouFundo")
    end if
end sub

sub aoInformouFundo(ev as Object)
    chamarFim(ev)
end sub

sub visualChegou(ev as Object)
    chamarFim(ev)
    m.global.visual = ev.getData()
    t = topo()
    if t <> invalid and t.hasField("novoVisual") then t.novoVisual = true
end sub

sub abrirLogin(msg as String)
    limparPilha()
    abrir("Login", { msg: msg })
end sub

sub abrirAtivacao()
    limparPilha()
    abrir("Ativacao", {})
end sub

' ── Pilha de telas ──────────────────────────────────────────────────
function topo() as Dynamic
    if m.telas.Count() = 0 then return invalid
    return m.telas[m.telas.Count() - 1]
end function

sub limparPilha()
    for each t in m.telas
        t.callFunc("encerrar")
        m.pilha.removeChild(t)
    end for
    m.telas = []
end sub

sub abrir(nome as String, args as Object)
    atual = topo()
    t = CreateObject("roSGNode", nome)
    if t = invalid then
        print "[ERRO] nao consegui criar a tela "; nome
        mostrarErro(tx("Não foi possível abrir esta tela. Tente novamente."))
        return
    end if
    try
        if atual <> invalid then atual.visible = false
        t.args = args
        t.observeField("acao", "aoAcao")
        m.pilha.appendChild(t)
        m.telas.Push(t)
        t.visible = true
        t.callFunc("iniciar")
    catch e
        print "[ERRO] abrir("; nome; "): "; sv(e.message); " #"; sv(e.number)
        mostrarErro(tx("Não foi possível abrir esta tela. Tente novamente."))
        if atual <> invalid then atual.visible = true
    end try
end sub

' Mostra um aviso de erro grande na tela por 20 segundos.
sub mostrarErro(texto as String)
    print "[ERRO] "; texto
    l = m.top.findNode("carregandoTxt")
    l.wrap = true
    l.maxLines = 8
    l.translation = [120, 300]
    l.width = 1680
    l.height = 480
    l.text = texto
    m.top.findNode("carregando").visible = true
    if m.timerErro = invalid then
        m.timerErro = CreateObject("roSGNode", "Timer")
        m.timerErro.repeat = false
        m.timerErro.duration = 20
        m.timerErro.observeField("fire", "esconderErro")
    end if
    m.timerErro.control = "stop"
    m.timerErro.control = "start"
end sub

sub esconderErro()
    m.top.findNode("carregando").visible = false
    t = topo()
    if t <> invalid then t.callFunc("retomar")
end sub

sub voltar()
    if m.telas.Count() <= 1 then return
    t = m.telas.Pop()
    t.callFunc("encerrar")
    m.pilha.removeChild(t)
    atual = topo()
    atual.visible = true
    atual.callFunc("retomar")
end sub

sub aoAcao(ev as Object)
    a = ev.getData()
    if a = invalid then return
    tipo = sv(a.tipo)
    if tipo = "abrir" then
        abrir(sv(a.tela), a.args)
    else if tipo = "voltar" then
        voltar()
    else if tipo = "erro" then
        mostrarErro(sv(a.texto))
    else if tipo = "entrou" then
        entrou(a, a.informar)
    else if tipo = "login" then
        abrirLogin(sv(a.msg))
    else if tipo = "ativacao" then
        abrirAtivacao()
    else if tipo = "trocarlista" then
        ' Lista nova escolhida em "Minhas listas": entra de novo com ela.
        mostrarCarregando("Entrando...")
        partidaEntrarLista()
    else if tipo = "carregando" then
        if a.ligado = true then mostrarCarregando(sv(a.texto)) else esconderCarregando()
    else if tipo = "idioma" then
        ' Idioma mudou: recria a pilha para refazer todos os textos.
        limparPilha()
        abrir("Home", {})
    else if tipo = "sair" then
        sessaoLimpar()
        limparPilha()
        abrirLogin("")
    end if
end sub

sub partidaEntrarLista()
    m.trocando = true
    s = sessaoLer()
    if s = invalid then
        esconderCarregando()
        abrirLogin("")
        return
    end if
    autenticarPar(ctxDaSessao(s), partidaEntrar)
end sub

sub mostrarCarregando(texto as String)
    m.top.findNode("carregandoTxt").text = tx(texto)
    m.top.findNode("carregando").visible = true
end sub

sub esconderCarregando()
    m.top.findNode("carregando").visible = false
    t = topo()
    if t <> invalid then t.callFunc("retomar")
end sub

' Botão Voltar que as telas não trataram: sobe uma tela; na primeira, a Roku fecha o app.
function onKeyEvent(tecla as String, pressionou as Boolean) as Boolean
    if not pressionou then return false
    if tecla = "back" then
        if m.telas.Count() > 1 then
            voltar()
            return true
        end if
    end if
    return false
end function

' ── Vigia da licença ────────────────────────────────────────────────
sub vigiar()
    if m.vigiando = true then return
    t = topo()
    if t = invalid then return
    if t.subtype() = "Login" or t.subtype() = "Ativacao" or t.subtype() = "Listas" then return
    if sessaoLer() = invalid then return
    m.vigiando = true
    chamar("AuthTask", "guarda", {}, "aoVigia")
end sub

sub aoVigia(ev as Object)
    chamarFim(ev)
    m.vigiando = false
    r = ev.getData()
    if r = invalid or r.ok <> true then return
    lic = r.lic
    estado = sv(lic.estado)
    if estado = "erro" or estado = "" then return   ' sem internet: não bloqueia
    t = topo()
    if t = invalid or t.subtype() = "Login" or t.subtype() = "Ativacao" or t.subtype() = "Listas" then return
    if sv(r.modo) <> "parceiro" or r.parceiroCaiu = true then m.global.lic = lic
    if r.parceiroCaiu = true then
        m.global.ehParceiro = false
        m.global.parceiroNome = ""
        sessaoLimpar()
        if estado = "expired" or estado = "blocked" then
            limparPilha()
            abrir("Ativacao", { msg: "O código de parceiro desta lista não está mais ativo. Para continuar, ative a licença desta TV." })
        else
            abrirLogin("O código de parceiro não está mais ativo. Entre com outra lista.")
        end if
    else if sv(r.modo) <> "parceiro" and estado <> "trial" and estado <> "active" then
        ' Lista comum e a TV não tem licença valendo (bloqueada, vencida ou revogada): bloqueia na hora.
        limparPilha()
        msg = "A licença desta TV venceu. Para continuar, ative."
        if estado = "blocked" then msg = "Esta TV foi bloqueada. Fale com o suporte."
        abrir("Ativacao", { msg: msg })
    end if
end sub

' ── Vigia do foco ───────────────────────────────────────────────────
' Roda a cada 1 s: se a tela de cima não está com o foco (e não há janela de diálogo aberta), devolve o foco.
sub garantirFoco()
    d = m.top.dialog
    if d <> invalid then
        if d.isInFocusChain() then return
    end if
    t = topo()
    if t = invalid then return
    if not t.visible then return
    if t.isInFocusChain() then return
    t.callFunc("focar")
    if not t.isInFocusChain() then t.setFocus(true)
end sub
