' VLTV Play - Roku | Controle parental: senha de 4 dígitos (padrão 0000), pergunta secreta e filtro +18.

function perguntasSecretas() as Object
    return [
        "Qual o nome do seu primeiro animal de estimação?",
        "Em que cidade você nasceu?",
        "Qual o nome da sua primeira escola?",
        "Qual o nome da sua melhor amiga ou do seu melhor amigo de infância?",
        "Qual o seu filme favorito?"
    ]
end function

function ehCatAdulta(nome as String) as Boolean
    if m.reAdCat = invalid then m.reAdCat = CreateObject("roRegex", "(^|[^a-z])(adult[oa]?s?|xxx|porn[oô]?|hentai|nsfw|er[oó]tic[oa]s?|sexy|sexo|sensual|playboy)([^a-z]|$)|\+\s?18|18\s?\+|\b18\s?anos", "i")
    return m.reAdCat.IsMatch(nome)
end function

function ehNomeAdulto(nome as String) as Boolean
    if m.reAdNome = invalid then m.reAdNome = CreateObject("roRegex", "(^|[^a-z])(xxx|porn[oô]?|hentai|nsfw)([^a-z]|$)|\+\s?18|18\s?\+|[\[\(]\s?adult[oa]?\s?[\]\)]", "i")
    return m.reAdNome.IsMatch(nome)
end function

' Classificação indicativa 18+ no "info" do painel.
function idadeAdulta(info as Dynamic) as Boolean
    if info = invalid or not isAA(info) then return false
    txt = UCase(sv(info.age))
    if txt = "" then txt = UCase(sv(info.mpaa_rating))
    if txt = "" then txt = UCase(sv(info.age_rating))
    if txt = "" then txt = UCase(sv(info.certification))
    if txt = "" then return false
    if m.reIdade = invalid then m.reIdade = CreateObject("roRegex", "(^|\D)18(\D|$)|NC-?17|^X$|R-?18|A-?18|\+\s?18", "i")
    return m.reIdade.IsMatch(txt)
end function

function parentalPadrao() as Object
    return { ativo: true, modo: "senha", pin: "", perg: -1, resp: "" }
end function

function parentalLer() as Object
    e = regJson("parental")
    if e = invalid or not isAA(e) then return parentalPadrao()
    if e.ativo = invalid then e.ativo = true
    if e.modo = invalid then e.modo = "senha"
    if e.pin = invalid then e.pin = ""
    if e.perg = invalid then e.perg = -1
    if e.resp = invalid then e.resp = ""
    return e
end function

sub parentalGravar(e as Object)
    regJsonSet("parental", e)
end sub

function hashParental(texto as String) as String
    ba = CreateObject("roByteArray")
    ba.FromAsciiString("vltv|" + texto)
    d = CreateObject("roEVPDigest")
    d.Setup("sha1")
    return d.Process(ba)
end function

function normalizarResposta(t as String) as String
    return norm(t)
end function

function pinConfere(pin as String) as Boolean
    e = parentalLer()
    if e.pin = "" then return pin = "0000"
    return hashParental(pin) = e.pin
end function

function respostaConfere(texto as String) as Boolean
    e = parentalLer()
    if e.resp = "" then return false
    return hashParental(normalizarResposta(texto)) = e.resp
end function

function senhaEhPadrao() as Boolean
    return parentalLer().pin = ""
end function

function temPergunta() as Boolean
    e = parentalLer()
    return e.perg >= 0 and e.resp <> ""
end function

function perguntaAtual() as String
    e = parentalLer()
    if e.perg < 0 then return ""
    p = perguntasSecretas()
    if e.perg < p.Count() then return p[e.perg]
    return ""
end function

sub parentalDefinirAtivo(v as Boolean)
    e = parentalLer()
    e.ativo = v
    parentalGravar(e)
end sub

sub parentalDefinirModo(modo as String)
    e = parentalLer()
    if modo = "ocultar" then e.modo = "ocultar" else e.modo = "senha"
    parentalGravar(e)
end sub

sub parentalDefinirPin(pin as String)
    e = parentalLer()
    e.pin = hashParental(pin)
    parentalGravar(e)
end sub

sub parentalDefinirPergunta(idx as Integer, resposta as String)
    e = parentalLer()
    e.perg = idx
    e.resp = hashParental(normalizarResposta(resposta))
    parentalGravar(e)
end sub

' true = o conteúdo +18 está protegido agora (ativo e ainda não liberado com a senha).
function parentalBloqueando() as Boolean
    return parentalLer().ativo and not m.global.parentalLiberado
end function

' Marca as categorias adultas (adulta = true). No modo "ocultar" elas somem enquanto bloqueado.
function filtrarCategoriasParental(lista as Object) as Object
    saida = []
    e = parentalLer()
    for each c in lista
        if ehCatAdulta(sv(c.category_name)) then
            if e.ativo and e.modo = "ocultar" and not m.global.parentalLiberado then
                ' fica de fora
            else
                c.adulta = true
                saida.Push(c)
            end if
        else
            saida.Push(c)
        end if
    end for
    return saida
end function

function itemAdultoParental(raw as Object, adultaCat as Boolean) as Boolean
    if adultaCat then return true
    v = LCase(sv(raw.is_adult))
    if v = "1" or v = "true" then return true
    return ehNomeAdulto(sv(raw.name))
end function

function filtrarItensParental(lista as Object, adultaCat as Boolean) as Object
    if not parentalBloqueando() then return lista
    saida = []
    for each x in lista
        if not itemAdultoParental(x, adultaCat) then saida.Push(x)
    end for
    return saida
end function
