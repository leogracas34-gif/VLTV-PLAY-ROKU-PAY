' VLTV Play - Roku | Configurações igual às da LG: menu 520 à esquerda, conteúdo 1250 à direita.

sub iniciar()
    carregarI18n()
    vkFundo(m.top)
    m.itens = [
        { id: "info", nome: "Informação geral" },
        { id: "idioma", nome: "Idioma" },
        { id: "parental", nome: "Controle parental" },
        { id: "cache", nome: "Limpar cache" },
        { id: "recarregar", nome: "Atualizar o aplicativo" },
        { id: "sobre", nome: "Sobre o aplicativo" }
    ]
    m.pm = vkPainel(m.top, 60, 60, 520, 960, tx("Configurações"), true)
    m.pc = vkPainel(m.top, 610, 60, 1250, 960, "", false)
    m.menu = vkLista(m.pm.grupo, 23, 83, 474, 850, 84, 6, 27)
    itens = []
    for each i in m.itens
        itens.Push({ nome: tx(i.nome) })
    end for
    vkListaItens(m.menu, itens)

    ' linhas do conteúdo (rótulo à esquerda, valor em negrito à direita)
    m.cl = []
    for i = 0 to 9
        g = uiNo(m.pc.grupo, "Group", { translation: [39, 103 + i * 84], visible: false })
        r = {}
        r.grupo = g
        r.fundo = vkNine(g, 0, 0, 1172, 82, "f12")
        r.fundo.blendColor = cDest()
        r.fundo.visible = false
        r.rot = vkTxt(g, 12, 0, 700, 82, "", 32, false, cSuave(), "left")
        r.val = vkTxt(g, 500, 0, 660, 82, "", 32, true, cTexto(), "right")
        r.lin = vkRet(g, 0, 82, 1172, 2, cBorda())
        m.cl.Push(r)
    end for
    m.txt = vkTxtM(m.pc.grupo, 51, 103, 1148, 700, "", 30, false, cSuave(), 12, "left")
    m.txtLinha = 0
    m.foco = "menu"
    m.dirIdx = 0
    m.dirItens = []
    m.idx = 0
    m.livre = true
    desenharDireita()
    m.top.setFocus(true)
end sub

sub retomar()
    m.top.setFocus(true)
end sub

sub focar()
    m.top.setFocus(true)
end sub

sub encerrar()
end sub

' ── conteúdo da direita ─────────────────────────────────────────────
sub limparDireita()
    for each r in m.cl
        r.grupo.visible = false
    end for
    m.n = 0
    m.txt.text = ""
end sub

' sel: linha selecionada (vermelha). classe: "ok" | "erro" | ""
sub cfgLinha(rotulo as String, valor as String, classe as String, sel as Boolean)
    if m.n > 9 then return
    r = m.cl[m.n]
    r.grupo.visible = true
    r.rot.text = tx(rotulo)
    r.val.text = valor
    r.fundo.visible = sel
    r.lin.visible = not sel
    if sel then
        r.rot.color = cBranco()
        r.val.color = cBranco()
    else
        r.rot.color = cSuave()
        if classe = "ok" then
            r.val.color = cOk()
        else if classe = "erro" then
            r.val.color = cErro()
        else
            r.val.color = cTexto()
        end if
    end if
    m.n = m.n + 1
end sub

sub txtBloco(t as String)
    m.txt.translation = [51, 103 + m.n * 84 + 10]
    m.txt.text = tx(t)
end sub

sub desenharDireita()
    item = m.itens[m.idx]
    m.pc.titulo.text = tx(item.nome)
    limparDireita()
    id = item.id
    if id = "info" then
        desenharInfo()
    else if id = "idioma" then
        desenharIdioma()
    else if id = "parental" then
        if m.foco = "dir" then
            desenharParental()
        else
            txtBloco("Bloqueia canais, filmes e séries adultos (+18) com uma senha de 4 dígitos. A senha padrão é 0000: crie a sua e escolha uma pergunta secreta para recuperar. Pressione OK para abrir (pede a senha).")
        end if
    else if id = "cache" then
        cfgLinha("O que será apagado", tx("Listas, banner e logos guardados"), "", false)
        cfgLinha("O que continua salvo", tx("Login, favoritos e ") + Chr(34) + tx("continuar assistindo") + Chr(34), "", false)
        cfgLinha("Depois de limpar", tx("O aplicativo reinicia sozinho"), "", false)
        txtBloco("Use quando algo estiver desatualizado ou lento. Pressione OK para limpar.")
    else if id = "recarregar" then
        cfgLinha("Versão instalada", sv(cfg().versao), "", false)
        t = licTextoCurto(m.global.lic, m.global.ehParceiro = true)
        if t <> "" then cfgLinha("Licença do aplicativo", tx(t), "ok", false)
        cfgLinha("Seu login e seus favoritos", tx("Continuam salvos"), "ok", false)
        txtBloco("Reinicia o aplicativo e carrega tudo de novo (lista, categorias e licença). Novas versões do aplicativo chegam pela loja de aplicativos da Roku. Pressione OK para atualizar.")
    else
        desenharSobre()
    end if
end sub

sub desenharInfo()
    info = m.global.info
    s = sessaoLer()
    if info <> invalid and isAA(info) and info.exp_date <> invalid then
        exp = iv(info.exp_date)
        dias = invalid
        if exp > 0 then dias = Int((exp - nowSec()) / 86400) + 1
        ativo = (LCase(sv(info.status)) = "active" or sv(info.status) = "") and (dias = invalid or dias >= 0)
        if ativo then
            cfgLinha("Canais, filmes e séries", tx("Ativo"), "ok", false)
        else
            cfgLinha("Canais, filmes e séries", tx("Expirado"), "erro", false)
        end if
        if exp > 0 then
            q = dataBr(exp)
            if dias <> invalid and dias >= 0 then
                if dias = 1 then q = q + " (1 " + tx("dia") + ")" else q = q + " (" + Str(dias).Trim() + " " + tx("dias") + ")"
            end if
            cfgLinha("Plano de canais, filmes e séries vence em", q, "", false)
        else
            cfgLinha("Plano de canais, filmes e séries vence em", tx("Sem vencimento"), "", false)
        end if
    else if s <> invalid and s.modo = "m3u" then
        cfgLinha("Canais, filmes e séries", tx("Lista M3U"), "ok", false)
    else
        cfgLinha("Canais, filmes e séries", tx("Ativo"), "ok", false)
    end if
    if s <> invalid then
        if sv(s.parceiro) <> "" then cfgLinha("Parceiro", sv(s.parceiro), "", false)
        if sv(s.user) <> "" then cfgLinha("Usuário", sv(s.user), "", false)
    end if
    cfgLinha("Versão do produto", sv(cfg().versao), "", false)
    if left(sv(cfg().tmdbKey), 2) <> "__" and sv(cfg().tmdbKey) <> "" then
        cfgLinha("Títulos e sinopses (TMDB)", tx("Conectado"), "ok", false)
    else
        cfgLinha("Títulos e sinopses (TMDB)", tx("Sem chave"), "erro", false)
    end if
    cfgLinha("Chave do dispositivo", chaveDispositivo(), "", false)
    lic = m.global.lic
    if lic <> invalid and isAA(lic) and sv(lic.codigo) <> "" then
        cfgLinha("Código da TV (ativação)", sv(lic.codigo), "", false)
        t = licTextoCurto(lic, m.global.ehParceiro = true)
        cfgLinha("Licença do aplicativo", tx(t), "ok", false)
    else
        cfgLinha("Licença do aplicativo", tx("Não verificada (sem resposta do servidor)"), "erro", false)
    end if
end sub

' 6 dígitos estáveis a partir do id do aparelho ("123 456").
function chaveDispositivo() as String
    base = licIdentidade().id
    n = 7
    for i = 1 to Len(base)
        n = (n * 31 + Asc(Mid(base, i, 1))) mod 1000000
    end for
    t = Right("00000" + Str(n).Trim(), 6)
    return Left(t, 3) + " " + Right(t, 3)
end function

sub desenharSobre()
    cfgLinha("Aplicativo", "VLTV Play", "", false)
    cfgLinha("Tipo", tx("Reprodutor de mídia"), "", false)
    cfgLinha("Versão", sv(cfg().versao), "", false)
    lic = m.global.lic
    if lic <> invalid and isAA(lic) and sv(lic.codigo) <> "" then
        cfgLinha("Código da TV", sv(lic.codigo), "", false)
        cfgLinha("Licença", tx(licTextoCurto(lic, m.global.ehParceiro = true)), "ok", false)
    end if
    if sv(cfg().suporte) <> "" then cfgLinha("Suporte", sv(cfg().suporte), "", false)
    ' Aviso legal: texto completo em português e inglês (o inglês vai direto, sem passar pelo tx()).
    if idiomaEn() then
        m.txt.translation = [51, 103 + m.n * 84 + 10]
        m.txt.text = "VLTV Play is only a media player. It does not sell, market or offer channels, movies, series or lists, and under no circumstances engages in or encourages piracy. To use the app, you need a service you subscribed to on your own from a provider of your choice. The app only plays that content."
    else
        txtBloco("O VLTV Play é apenas um reprodutor de mídia. Ele não vende, não comercializa e não oferece canais, filmes, séries ou listas, e em hipótese alguma pratica ou incentiva pirataria. Para usar o aplicativo, você precisa ter um serviço contratado por conta própria com um provedor da sua preferência. O aplicativo apenas reproduz esse conteúdo.")
    end if
end sub

sub desenharIdioma()
    atual = "pt-BR"
    if idiomaEn() then atual = "en"
    m.dirItens = [{ codigo: "pt-BR", nome: "Português (Brasil)" }, { codigo: "en", nome: "English" }]
    if m.foco <> "dir" then
        m.dirIdx = 0
        if atual = "en" then m.dirIdx = 1
    end if
    for i = 0 to 1
        it = m.dirItens[i]
        marca = ""
        if it.codigo = atual then marca = Chr(9679)
        r = m.cl[m.n]
        cfgLinha(it.nome, marca, "ok", (m.foco = "dir" and i = m.dirIdx))
        r.rot.text = it.nome
    end for
    txtBloco("Escolha o idioma do aplicativo. A mudança vale na hora: o aplicativo reinicia sozinho.")
end sub

sub desenharParental()
    e = parentalLer()
    m.dirItens = []
    m.dirItens.Push({ id: "ativo" })
    m.dirItens.Push({ id: "modo" })
    m.dirItens.Push({ id: "senha" })
    m.dirItens.Push({ id: "pergunta" })
    if m.dirIdx > 3 then m.dirIdx = 3
    if e.ativo then
        cfgLinha("Bloqueio de conteúdo adulto", tx("Ativado"), "ok", m.dirIdx = 0)
    else
        cfgLinha("Bloqueio de conteúdo adulto", tx("Desativado"), "erro", m.dirIdx = 0)
    end if
    if e.modo = "ocultar" then
        cfgLinha("Conteúdo bloqueado", tx("Ocultar"), "", m.dirIdx = 1)
    else
        cfgLinha("Conteúdo bloqueado", tx("Pedir senha"), "", m.dirIdx = 1)
    end if
    if senhaEhPadrao() then
        cfgLinha("Senha", tx("Padrão (0000) - alterar"), "erro", m.dirIdx = 2)
    else
        cfgLinha("Senha", tx("Personalizada - alterar"), "ok", m.dirIdx = 2)
    end if
    if temPergunta() then
        cfgLinha("Pergunta secreta", tx("Definida - alterar"), "ok", m.dirIdx = 3)
    else
        cfgLinha("Pergunta secreta", tx("Não definida - criar"), "erro", m.dirIdx = 3)
    end if
    if senhaEhPadrao() then
        txtBloco("Você ainda usa a senha padrão (0000). Crie a sua para proteger de verdade.")
    else
        txtBloco("Com o bloqueio ativado, categorias, canais e filmes adultos pedem a senha (ou ficam ocultos). Depois de digitada, a senha libera o conteúdo até voltar para a tela inicial.")
    end if
end sub

' ── ações ───────────────────────────────────────────────────────────
sub abrirParental()
    uiSenha("Controle parental", "Digite a senha para abrir.", parentalAberto)
end sub

sub parentalAberto()
    m.foco = "dir"
    m.dirIdx = 0
    desenharDireita()
end sub

sub criouSenha()
    desenharDireita()
end sub

sub limpar()
    limparDireita()
    txtBloco("Cache limpo. Reiniciando o aplicativo...")
    limparCacheTudo()
    m.livre = false
    m.tempo = uiNo(m.top, "Timer", { duration: 0.9, repeat: false })
    m.tempo.observeField("fire", "reiniciar")
    m.tempo.control = "start"
end sub

sub reiniciar()
    uiAcao("idioma", invalid)
end sub

sub atualizar()
    limparDireita()
    txtBloco("Atualizando...")
    m.livre = false
    m.tempo = uiNo(m.top, "Timer", { duration: 0.4, repeat: false })
    m.tempo.observeField("fire", "recarregarApp")
    m.tempo.control = "start"
end sub

sub recarregarApp()
    uiAcao("carregando", { ligado: true, texto: "Atualizando..." })
    uiAcao("trocarlista", invalid)
end sub

sub trocarIdioma(codigo as String)
    regSet("idioma", codigo)
    m.global.idioma = codigo
    uiAcao("idioma", invalid)
end sub

function teclaDireita(tecla as String) as Boolean
    if tecla = "left" or tecla = "back" then
        m.foco = "menu"
        desenharDireita()
    else if tecla = "up" then
        if m.dirIdx > 0 then
            m.dirIdx = m.dirIdx - 1
            desenharDireita()
        end if
    else if tecla = "down" then
        if m.dirIdx < m.dirItens.Count() - 1 then
            m.dirIdx = m.dirIdx + 1
            desenharDireita()
        end if
    else if tecla = "OK" then
        id = m.itens[m.idx].id
        if id = "idioma" then
            trocarIdioma(m.dirItens[m.dirIdx].codigo)
            return true
        end if
        a = m.dirItens[m.dirIdx].id
        e = parentalLer()
        if a = "ativo" then
            parentalDefinirAtivo(not e.ativo)
            m.global.parentalLiberado = false
        else if a = "modo" then
            if e.modo = "ocultar" then parentalDefinirModo("senha") else parentalDefinirModo("ocultar")
        else
            uiCriarSenha(criouSenha)
        end if
        desenharDireita()
    else
        return false
    end if
    return true
end function

function onKeyEvent(tecla as String, pressionou as Boolean) as Boolean
    if not pressionou then return false
    if not m.livre then return true
    if m.foco = "dir" then return teclaDireita(tecla)
    if tecla = "up" then
        if m.idx > 0 then
            m.idx = m.idx - 1
            m.menu.idx = m.idx
            vkListaIr(m.menu, m.idx)
            desenharDireita()
        end if
    else if tecla = "down" then
        if m.idx < m.itens.Count() - 1 then
            m.idx = m.idx + 1
            vkListaIr(m.menu, m.idx)
            desenharDireita()
        end if
    else if tecla = "OK" or tecla = "right" then
        id = m.itens[m.idx].id
        if id = "parental" then
            abrirParental()
        else if id = "idioma" then
            m.foco = "dir"
            desenharDireita()
        else if tecla = "right" then
            return true
        else if id = "cache" then
            limpar()
        else if id = "recarregar" then
            atualizar()
        end if
    else
        return false
    end if
    return true
end function
