' VLTV Play - Roku | Ajudantes de tela (criar nós, tarefas, diálogos). Usado só nas telas.

function uiFundo() as String
    return "0x0A0A0CFF"
end function
function uiPainel() as String
    return "0x141416FF"
end function
function uiTexto() as String
    return "0xF5F5F7FF"
end function
function uiSuave() as String
    return "0x9C9CA8FF"
end function
function uiDestaque() as String
    return "0xE50914FF"
end function
function uiOk() as String
    return "0x5BE3A4FF"
end function
function uiErro() as String
    return "0xFF8A92FF"
end function

function uiNo(pai as Dynamic, tipo as String, props as Object) as Object
    n = CreateObject("roSGNode", tipo)
    if props <> invalid then
        if props.font <> invalid and Type(props.font) = "String" then
            f = CreateObject("roSGNode", "Font")
            f.uri = props.font
            f.size = 28
            props.font = f
        end if
        n.setFields(props)
    end if
    if pai <> invalid then pai.appendChild(n)
    return n
end function

function uiRet(pai as Object, x as Integer, y as Integer, w as Integer, h as Integer, cor as String) as Object
    return uiNo(pai, "Rectangle", { translation: [x, y], width: w, height: h, color: cor })
end function

' fonte: "font:MediumSystemFont", "font:LargeBoldSystemFont"...
function uiTxt(pai as Object, x as Integer, y as Integer, w as Integer, h as Integer, texto as String, fonte as String, cor as String) as Object
    return uiNo(pai, "Label", { translation: [x, y], width: w, height: h, text: tx(texto), font: fonte, color: cor, wrap: true, lineSpacing: 0 })
end function

function uiLinha(pai as Object, x as Integer, y as Integer, w as Integer, texto as String, fonte as String, cor as String) as Object
    return uiNo(pai, "Label", { translation: [x, y], width: w, text: tx(texto), font: fonte, color: cor, wrap: false, truncateOnDelimiter: "" , ellipsisText: "..." })
end function

function uiFoto(pai as Object, x as Integer, y as Integer, w as Integer, h as Integer, uri as String, zoom as Boolean) as Object
    modo = "scaleToFit"
    if zoom then modo = "scaleToZoom"
    return uiNo(pai, "Poster", { translation: [x, y], width: w, height: h, uri: uri, loadDisplayMode: modo })
end function

' Lista de textos com o visual do VLTV (barra vermelha no foco).
function uiLista(pai as Object, x as Integer, y as Integer, w as Integer, linhas as Integer, alturaItem as Integer) as Object
    return uiNo(pai, "LabelList", {
        translation: [x, y], itemSize: [w, alturaItem], numRows: linhas,
        focusBitmapUri: "pkg:/images/foco.png", focusFootprintBitmapUri: "pkg:/images/foco_inativo.png",
        color: "0xF5F5F7FF", focusedColor: "0xFFFFFFFF", textHorizOffset: 20, vertFocusAnimationStyle: "floatingFocus",
        itemSpacing: [0, 4]
    })
end function

function uiItensLista(textos as Object) as Object
    raiz = CreateObject("roSGNode", "ContentNode")
    for each t in textos
        c = raiz.createChild("ContentNode")
        c.title = tx(sv(t))
    end for
    return raiz
end function

function uiBotoes(pai as Object, x as Integer, y as Integer, textos as Object, horizontal as Boolean) as Object
    b = uiNo(pai, "ButtonGroup", {
        translation: [x, y], buttons: [], iconUri: "", focusBitmapUri: "pkg:/images/foco.png", focusFootprintBitmapUri: "pkg:/images/foco_inativo.png",
        textColor: "0xF5F5F7FF", focusedTextColor: "0xFFFFFFFF", minWidth: 280, maxWidth: 520, itemSpacings: [12]
    })
    if horizontal then b.layoutDirection = "horiz"
    lista = []
    for each t in textos
        lista.Push(tx(sv(t)))
    end for
    b.buttons = lista
    return b
end function

' ── Tarefas (rede) ──────────────────────────────────────────────────
' Roda uma tarefa e chama a função "cb" com o resultado. Devolve o nó (id = número do pedido).
function chamar(tarefa as String, op as String, params as Object, cb as String) as Object
    if m.tarefas = invalid then m.tarefas = {}
    if m.seqTarefa = invalid then m.seqTarefa = 0
    m.seqTarefa = m.seqTarefa + 1
    t = CreateObject("roSGNode", tarefa)
    t.id = "t" + Str(m.seqTarefa).Trim()
    t.observeField("result", cb)
    t.op = op
    if tarefa = "AuthTask" then
        t.ctx = params
    else
        t.params = params
    end if
    m.tarefas[t.id] = t
    t.control = "RUN"
    return t
end function

sub chamarFim(ev as Object)
    if m.tarefas <> invalid then m.tarefas.Delete(ev.getRoSGNode().id)
end sub

' Pedido ainda é o último daquele tipo? (descarta respostas velhas)
function pedidoAtual(chave as String, ev as Object) as Boolean
    n = ev.getRoSGNode()
    chamarFim(ev)
    if m.ultimo = invalid then m.ultimo = {}
    return m.ultimo[chave] = n.id
end function

sub marcarPedido(chave as String, t as Object)
    if m.ultimo = invalid then m.ultimo = {}
    m.ultimo[chave] = t.id
end sub

' ── Janelas por cima da tela (visual do app) ─────────────────────────
' Abre a janela "nome" dentro da tela atual. Quando ela termina, chama m.janelaCb(resultado) e devolve o foco à tela.
sub uiJanela(nome as String, args as Object, cb as Dynamic)
    j = CreateObject("roSGNode", nome)
    j.args = args
    m.janelaCb = cb
    m.janelaNo = j
    j.observeFieldScoped("resultado", "uiJanelaFim")
    m.top.appendChild(j)
    j.callFunc("iniciar")
end sub

sub uiJanelaFim(ev as Object)
    r = ev.getData()
    j = m.janelaNo
    cb = m.janelaCb
    m.janelaCb = invalid
    m.janelaNo = invalid
    if j <> invalid then m.top.removeChild(j)
    m.top.callFunc("focar")
    if cb <> invalid then cb(r)
end sub

function uiJanelaAberta() as Boolean
    return m.janelaNo <> invalid
end function

sub uiAviso(titulo as String, mensagemTxt as String)
    uiJanela("JConfirma", { titulo: titulo, msg: mensagemTxt, botoes: ["OK"], perigo: -1 }, invalid)
end sub

' Teclado na tela. cb(texto) é chamado só se a pessoa confirmar.
sub uiTeclado(titulo as String, dica as String, atual as String, senha as Boolean, cb as Function)
    m.tecladoCb = cb
    uiJanela("JTeclado", { titulo: titulo, dica: dica, atual: atual, senha: senha }, uiTecladoFim)
end sub

sub uiTecladoFim(r as Object)
    if r.ok = true then m.tecladoCb(sv(r.texto))
end sub

' Pede a senha dos pais. cbOk() é chamado se acertar (ou se recuperar a senha).
sub uiSenha(titulo as String, sub1 as String, cbOk as Function)
    m.senhaCb = cbOk
    uiJanela("JPin", { modo: "pedir", titulo: titulo, sub: sub1 }, uiSenhaFim)
end sub

' Criar (ou trocar) a senha e a pergunta secreta. cbFim() é chamado ao terminar.
sub uiCriarSenha(cbFim as Function)
    m.senhaCb = cbFim
    uiJanela("JPin", { modo: "criar" }, uiSenhaFim)
end sub

sub uiSenhaFim(r as Object)
    if r.ok = true then
        m.global.parentalLiberado = true
        m.senhaCb()
    end if
end sub

' Pergunta Sim/Não. cb() é chamado no botão "sim" (o botão "não" vem primeiro, como na LG).
sub uiConfirmar(titulo as String, mensagemTxt as String, sim as String, nao as String, cb as Function)
    m.confCb = cb
    uiJanela("JConfirma", { titulo: titulo, msg: mensagemTxt, botoes: [nao, sim], perigo: 1, foco: 0 }, uiConfirmarFim)
end sub

sub uiConfirmarFim(r as Object)
    if r.indice = 1 then m.confCb()
end sub

sub uiAcao(tipo as String, extra as Object)
    a = { tipo: tipo }
    if extra <> invalid then a.Append(extra)
    m.top.acao = a
end sub

' Nota "7.8" a partir do campo rating do painel.
function uiNota(v as Dynamic) as String
    n = nv(v)
    if n <= 0 then return ""
    return Str(Int(n * 10 + 0.5) / 10).Trim()
end function

' ── Entrar numa lista: licença e login ao mesmo tempo ────────────────
' Antes eram 3 chamadas em fila (licença, login, aviso à VPS). Agora a licença e o login rodam juntos
' e o aviso à VPS vai depois, por trás. cb(r) recebe { estado, base, info, nome, painel, teste, lic }.
sub autenticarPar(ctx as Object, cb as Function)
    m.parCb = cb
    m.parLogin = invalid
    m.parLic = invalid
    m.parPrecisaLic = (sv(ctx.modo) <> "parceiro")
    t = chamar("AuthTask", "login", ctx, "aoParLogin")
    m.parIdLogin = t.id
    m.parIdLic = ""
    if m.parPrecisaLic then
        t2 = chamar("AuthTask", "licnova", {}, "aoParLic")
        m.parIdLic = t2.id
    end if
end sub

sub aoParLogin(ev as Object)
    id = ev.getRoSGNode().id
    chamarFim(ev)
    if id <> m.parIdLogin then return   ' resposta de uma tentativa antiga
    m.parLogin = ev.getData()
    parTentar()
end sub

sub aoParLic(ev as Object)
    id = ev.getRoSGNode().id
    chamarFim(ev)
    if id <> m.parIdLic then return
    m.parLic = ev.getData()
    parTentar()
end sub

function uiLiberaComum(lic as Dynamic) as Boolean
    if lic = invalid then return false
    if not isAA(lic) then return false
    return sv(lic.estado) = "active" or sv(lic.estado) = "trial"
end function

sub parTentar()
    if m.parLogin = invalid then return
    if m.parPrecisaLic and m.parLic = invalid then return
    r = m.parLogin
    cb = m.parCb
    m.parCb = invalid
    if cb = invalid then return
    if m.parPrecisaLic then
        if uiLiberaComum(m.parLic) then
            r.lic = m.parLic
        else
            ' Sem licença valendo: não entra. Se havia uma lista de parceiro em uso, devolve o aviso dela à VPS.
            antigo = regGet("lic_parc")
            if antigo <> "" then chamar("AuthTask", "informar", { codigo: antigo }, "aoParInformou")
            r = { estado: "sem_licenca", lic: m.parLic }
        end if
    end if
    cb(r)
end sub

sub aoParInformou(ev as Object)
    chamarFim(ev)
end sub

' Janela de escolha. cb(indice) só é chamado se a pessoa escolher algo.
sub uiEscolher(titulo as String, itens as Object, atual as Integer, cb as Function)
    m.escolherCb = cb
    uiJanela("JLista", { titulo: titulo, itens: itens, atual: atual }, uiEscolherFim)
end sub

sub uiEscolherFim(r as Object)
    if r.indice <> invalid and r.indice >= 0 then m.escolherCb(r.indice)
end sub
