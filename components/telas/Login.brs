' VLTV Play - Roku | Login igual ao da LG: logo, abas Usuário / Xtream / Lista M3U, campos 900x80, olho, Entrar 900x96.
' Foco manual: aba -> campos -> Entrar. No campo do servidor, um código de parceiro também vale.

sub iniciar()
    carregarI18n()
    m.modo = ultimaAba()
    if m.modo = "parceiro" then m.modo = "xtream"
    m.vals = regJson("form")
    if m.vals = invalid or not isAA(m.vals) then m.vals = {}
    m.ocupado = false
    m.ver = false
    m.fi = 0
    m.sb = 0

    vkFundo(m.top)
    m.logo = vkImg(m.top, 760, 100, 399, 44, "logo_64", "")
    m.llRot = vkTxt(m.top, 1260, 60, 600, 30, tx("Código da TV"), 22, false, cSuave(), "right")
    m.llCod = vkTxt(m.top, 1260, 94, 600, 50, "", 40, true, cTexto(), "right")
    c = ""
    if m.global.lic <> invalid then c = sv(m.global.lic.codigo)
    if c = "" then c = sv(regGet("codigoTv"))
    m.llCod.text = c
    m.llRot.visible = (c <> "")

    m.abas = []
    rot = ["Usuário", "Xtream", "Lista M3U"]
    for i = 0 to 2
        b = vkBotao(m.top, 510 + i * 305, 0, 289, 80, tx(rot[i]), 28)
        m.abas.Push(b)
    end for

    m.campos = {}
    m.campos.servidor = campoNovo("Servidor ou código de parceiro", "http://servidor.com:8080  ou  código", 900)
    m.campos.user = campoNovo("Usuário", "", 900)
    m.campos.pass = campoNovo("Senha", "", 804)
    m.campos.m3u = campoNovo("Endereço da lista M3U", "http://servidor.com/lista.m3u", 900)
    m.olho = vkCaixa(m.top, 1314, 0, 96, 80, 14, 3, 6)
    m.olhoImg = vkImg(m.olho.grupo, 28, 20, 40, 40, "i_olho", cSuave())
    m.olho.grupo.visible = false

    m.entrar = vkBotao(m.top, 510, 0, 900, 96, tx("Entrar"), 38)
    m.status = vkTxtM(m.top, 510, 0, 900, 70, "", 30, false, cSuave(), 2, "center")

    msg = sv(m.top.args.msg)
    if msg <> "" then mostrarStatus(tx(msg), true)
    layout()
    m.top.setFocus(true)
end sub

function campoNovo(rot as String, ph as String, w as Integer) as Object
    c = {}
    c.rot = vkTxt(m.top, 510, 0, 900, 36, tx(rot), 30, false, cSuave(), "left")
    c.caixa = vkCaixa(m.top, 510, 0, w, 80, 14, 3, 6)
    c.txt = vkTxt(c.caixa.grupo, 28, 0, w - 56, 80, "", 38, false, cTexto(), "left")
    c.ph = ph
    c.w = w
    return c
end function

sub retomar()
    m.top.setFocus(true)
end sub

sub encerrar()
end sub

sub focar()
    m.top.setFocus(true)
end sub

function chaves() as Object
    if m.modo = "m3u" then return ["m3u"]
    if m.modo = "xtream" then return ["servidor", "user", "pass"]
    return ["user", "pass"]
end function

function chaveVal(k as String) as String
    if k = "user" or k = "pass" then return m.modo + "_" + k
    return k
end function

' Posiciona tudo centralizado na vertical (como o flex da LG) e repinta.
sub layout()
    ks = chaves()
    total = 398 + 144 * ks.Count()
    y = 60 + Int((960 - total) / 2)
    m.logo.translation = [761, y + 16]
    y = y + 100
    for i = 0 to 2
        m.abas[i].caixa.grupo.translation = [510 + i * 305, y]
    end for
    y = y + 104
    for each k in ["servidor", "user", "pass", "m3u"]
        c = m.campos[k]
        vis = false
        for each q in ks
            if q = k then vis = true
        end for
        c.rot.visible = vis
        c.caixa.grupo.visible = vis
        if vis then
            c.rot.translation = [510, y]
            c.caixa.grupo.translation = [510, y + 46]
            if k = "pass" then m.olho.grupo.translation = [1314, y + 46]
            y = y + 144
        end if
    end for
    m.olho.grupo.visible = (m.modo <> "m3u")
    m.entrar.caixa.grupo.translation = [510, y + 12]
    m.status.translation = [510, y + 12 + 96 + 16]
    ' ordem do foco
    m.ordem = ["aba"]
    for each k in ks
        m.ordem.Push(k)
    end for
    m.ordem.Push("entrar")
    if m.fi >= m.ordem.Count() then m.fi = m.ordem.Count() - 1
    pintar()
end sub

sub pintar()
    foco = m.ordem[m.fi]
    for i = 0 to 2
        b = m.abas[i]
        ativa = ((i = 0 and m.modo = "usuario") or (i = 1 and m.modo = "xtream") or (i = 2 and m.modo = "m3u"))
        if foco = "aba" and ativa then
            vkPintar(b.caixa, cBranco(), cDest(), true)
            b.caixa.glow.opacity = 0.5
            b.txt.color = cBranco()
        else if ativa then
            vkPintar(b.caixa, cClaro(), cFundoPainel(), false)
            b.txt.color = cBranco()
        else
            vkPintar(b.caixa, cBorda(), cFundoPainel(), false)
            b.txt.color = cSuave()
        end if
    end for
    for each k in chaves()
        c = m.campos[k]
        v = sv(m.vals[chaveVal(k)])
        if k = "pass" and not m.ver then
            mascara = ""
            for j = 1 to Len(v)
                mascara = mascara + Chr(8226)
            end for
            v = mascara
        end if
        if v = "" then
            c.txt.text = c.ph
            c.txt.color = "0x5F5F6BFF"
        else
            c.txt.text = v
            c.txt.color = cTexto()
        end if
        if foco = k and m.sb = 0 then
            vkPintar(c.caixa, cClaro(), cFundoPainel(), true)
            c.caixa.glow.opacity = 0.35
        else
            vkPintar(c.caixa, cBorda(), cFundoPainel(), false)
        end if
    end for
    if foco = "pass" and m.sb = 1 then
        vkPintar(m.olho, cBranco(), cDest(), true)
        m.olho.glow.opacity = 0.5
        m.olhoImg.blendColor = cBranco()
    else
        vkPintar(m.olho, cBorda(), cFundoPainel(), false)
        m.olhoImg.blendColor = cSuave()
    end if
    if m.ver then m.olhoImg.uri = "pkg:/images/ui/i_olho_cortado.png" else m.olhoImg.uri = "pkg:/images/ui/i_olho.png"
    if foco = "entrar" then
        vkPintar(m.entrar.caixa, cBranco(), cDest(), true)
        m.entrar.caixa.glow.opacity = 0.5
    else
        vkPintar(m.entrar.caixa, "", cDest(), false)
    end if
    if m.ocupado then m.entrar.caixa.grupo.opacity = 0.55 else m.entrar.caixa.grupo.opacity = 1
end sub

sub mostrarStatus(texto as String, erro as Boolean)
    m.status.text = texto
    if erro then m.status.color = cErro() else m.status.color = cSuave()
end sub

sub trocarModo(novo as String)
    if novo = m.modo then return
    m.modo = novo
    m.sb = 0
    mostrarStatus("", false)
    layout()
end sub

function onKeyEvent(tecla as String, pressionou as Boolean) as Boolean
    if not pressionou then return false
    if m.ocupado then return true
    foco = m.ordem[m.fi]
    if tecla = "up" then
        m.sb = 0
        if m.fi > 0 then m.fi = m.fi - 1
        pintar()
        return true
    else if tecla = "down" then
        m.sb = 0
        if m.fi < m.ordem.Count() - 1 then m.fi = m.fi + 1
        pintar()
        return true
    else if tecla = "left" then
        if foco = "aba" then
            modos = ["usuario", "xtream", "m3u"]
            i = indiceModo()
            if i > 0 then trocarModo(modos[i - 1])
        else if foco = "pass" and m.sb = 1 then
            m.sb = 0
            pintar()
        end if
        return true
    else if tecla = "right" then
        if foco = "aba" then
            modos = ["usuario", "xtream", "m3u"]
            i = indiceModo()
            if i < 2 then trocarModo(modos[i + 1])
        else if foco = "pass" and m.sb = 0 then
            m.sb = 1
            pintar()
        end if
        return true
    else if tecla = "OK" then
        if foco = "aba" then
            m.fi = 1
            pintar()
        else if foco = "entrar" then
            entrar()
        else if foco = "pass" and m.sb = 1 then
            m.ver = not m.ver
            pintar()
        else
            abrirCampo(foco)
        end if
        return true
    end if
    return false
end function

function indiceModo() as Integer
    if m.modo = "xtream" then return 1
    if m.modo = "m3u" then return 2
    return 0
end function

sub abrirCampo(k as String)
    m.campoAtual = k
    rot = m.campos[k].rot.text
    uiTeclado(rot, "", sv(m.vals[chaveVal(k)]), (k = "pass"), tecladoOk)
end sub

' Terminou de digitar: vai para o próximo campo; se era o último, entra (igual à LG).
sub tecladoOk(texto as String)
    m.vals[chaveVal(m.campoAtual)] = texto.Trim()
    ks = chaves()
    ultimo = ks[ks.Count() - 1]
    m.sb = 0
    if m.campoAtual = ultimo then
        m.fi = m.ordem.Count() - 1
        pintar()
        entrar()
    else
        m.fi = m.fi + 1
        pintar()
    end if
end sub

' ── Entrar ──────────────────────────────────────────────────────────
sub entrar()
    ctx = { modo: m.modo }
    mostrarStatus(tx(""), true)
    if m.modo = "m3u" then
        u = sv(m.vals.m3u)
        if u = "" then
            mostrarStatus(tx("Digite o endereço da lista."), true)
            return
        end if
        if not startsWith(LCase(u), "http") then u = "http://" + u
        ctx.m3u = u
    else
        user = sv(m.vals[m.modo + "_user"])
        pass = sv(m.vals[m.modo + "_pass"])
        if user = "" or pass = "" then
            mostrarStatus(tx("Digite o usuário e a senha."), true)
            return
        end if
        ctx.user = user
        ctx.pass = pass
        if m.modo = "xtream" then
            srv = sv(m.vals.servidor)
            if srv = "" then
                mostrarStatus(tx("Digite o servidor ou o código do parceiro."), true)
                return
            end if
            ' Sem ponto, dois-pontos ou barra: é um código de parceiro.
            if Instr(1, srv, ".") = 0 and Instr(1, srv, ":") = 0 and Instr(1, srv, "/") = 0 then
                ctx.modo = "parceiro"
                ctx.codigo = srv
                ctx.dnsPreferido = ""
            else
                ctx.servidor = srv
            end if
        end if
    end if
    m.ctx = ctx
    regJsonSet("form", m.vals)
    regSet("aba", m.modo)
    m.ocupado = true
    pintar()
    mostrarStatus(tx("Entrando..."), false)
    uiAcao("carregando", { ligado: true, texto: "Entrando..." })
    autenticarPar(ctx, aoResultado)
end sub

sub aoResultado(r as Object)
    m.ocupado = false
    estado = sv(r.estado)
    pintar()
    if estado = "ok" then
        guardarSessao(r)
        return
    end if
    uiAcao("carregando", { ligado: false })
    if estado = "sem_licenca" then
        if r.lic <> invalid then m.global.lic = r.lic
        regSet("pendente", "1")   ' depois de ativar, volta aqui para abrir ESTA lista
        uiAcao("ativacao", invalid)
        return
    end if
    mostrarStatus(tx(mensagemDe(estado, r)), true)
    m.top.setFocus(true)
end sub

function mensagemDe(estado as String, r as Object) as String
    if estado = "expirado" then
        if r.teste = true then return "O teste dessa lista terminou."
        return "Essa lista está vencida. Fale com o seu provedor."
    else if estado = "invalido" then
        return "Usuário ou senha incorretos."
    else if estado = "codigo_invalido" then
        return "Código de parceiro não encontrado."
    else if estado = "suspenso" then
        return "Esse código de parceiro está suspenso."
    else if estado = "limite" then
        return "Muitas tentativas. Espere um pouco e tente de novo."
    else if estado = "m3u_grande" then
        return "A lista M3U é grande demais para a Roku."
    else if estado = "m3u_vazia" then
        return "A lista M3U não tem canais, filmes ou séries."
    end if
    return "Não foi possível conectar. Confira o endereço e a internet."
end function

sub guardarSessao(r as Object)
    c = m.ctx
    d = { modo: c.modo }
    if c.modo = "m3u" then
        d.m3u = c.m3u
    else
        d.user = c.user
        d.pass = c.pass
        if c.modo = "parceiro" then
            d.codigo = UCase(c.codigo)
            d.dns = sv(r.base)
            d.parceiro = sv(r.nome)
        else if c.modo = "xtream" then
            d.dns = sv(r.base)
        else
            d.painel = sv(r.painel)
        end if
    end if
    regSet("pendente", "")
    sessaoSalvar(d)
    listaRegistrar(d)
    ' Entra na hora. O aviso à VPS (código de parceiro = TV ativa; outra lista = sem parceiro) vai por trás.
    codigo = ""
    if c.modo = "parceiro" then codigo = UCase(c.codigo)
    if r.lic <> invalid then m.global.lic = r.lic
    uiAcao("carregando", { ligado: false })
    uiAcao("entrou", { info: r.info, base: sv(r.base), nome: sv(r.nome), informar: codigo })
end sub

