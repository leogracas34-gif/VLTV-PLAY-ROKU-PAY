' VLTV Play - Roku | Utilidades de texto, tempo e conversão (usadas por telas e tarefas).

' Qualquer valor vindo do painel (texto, número, nulo) vira texto. O Xtream mistura os tipos.
function sv(v as Dynamic) as String
    if v = invalid then return ""
    t = Type(v)
    if t = "String" or t = "roString" then return v
    if t = "Integer" or t = "roInt" or t = "roInteger" or t = "LongInteger" or t = "roLongInteger" or t = "Float" or t = "roFloat" or t = "Double" or t = "roDouble" then return Str(v).Trim()
    if t = "Boolean" or t = "roBoolean" then
        if v then return "true"
        return "false"
    end if
    return ""
end function

' Número vindo do painel (pode ser texto). Devolve 0 se não der.
function nv(v as Dynamic) as Double
    s = sv(v)
    if s = "" then return 0
    return Val(s)
end function

function iv(v as Dynamic) as Integer
    return Int(nv(v))
end function

function isLista(v as Dynamic) as Boolean
    return Type(v) = "roArray"
end function

function isAA(v as Dynamic) as Boolean
    return Type(v) = "roAssociativeArray"
end function

' Codifica para URL (igual ao Escape do roUrlTransfer). Feito na mão de propósito: o roUrlTransfer
' NÃO pode ser criado nas telas (só dentro de Task); lá o CreateObject devolvia invalid e dava
' "'Dot' Operator attempted with invalid BrightScript Component" ao apertar ASSISTIR.
function urlEnc(s as String) as String
    if s = "" then return ""
    ba = CreateObject("roByteArray")
    ba.FromAsciiString(s)
    hex = "0123456789ABCDEF"
    saida = ""
    for i = 0 to ba.Count() - 1
        b = ba[i]
        if (b >= 48 and b <= 57) or (b >= 65 and b <= 90) or (b >= 97 and b <= 122) or b = 45 or b = 46 or b = 95 or b = 126 then
            saida = saida + Chr(b)
        else
            saida = saida + "%" + Mid(hex, Int(b / 16) + 1, 1) + Mid(hex, (b mod 16) + 1, 1)
        end if
    end for
    return saida
end function

function nowSec() as Integer
    return CreateObject("roDateTime").AsSeconds()
end function

function nowMs() as LongInteger
    d = CreateObject("roDateTime")
    return d.AsSeconds() * 1000& + d.GetMilliseconds()
end function

function startsWith(s as String, p as String) as Boolean
    return Left(s, Len(p)) = p
end function

function endsWith(s as String, p as String) as Boolean
    if Len(p) > Len(s) then return false
    return Right(s, Len(p)) = p
end function

function contem(s as String, p as String) as Boolean
    return Instr(1, s, p) > 0
end function

' Tira as barras do fim.
function semBarraFinal(s as String) as String
    r = s
    while Len(r) > 0 and Right(r, 1) = "/"
        r = Left(r, Len(r) - 1)
    end while
    return r
end function

' "dns.com:8080" -> "http://dns.com:8080"
function normalizarDns(u as String) as String
    t = u.Trim()
    if t = "" then return ""
    l = LCase(t)
    if not startsWith(l, "http://") and not startsWith(l, "https://") then t = "http://" + t
    return semBarraFinal(t)
end function

' ---- acentos e normalização (mesma regra do índice da VPS) ----
function semAcento(s as String) as String
    tabu = "AAAAAAACEEEEIIIIDNOOOOOxOUUUUYTsaaaaaaaceeeeiiiidnooooo/ouuuuyty"
    achou = false
    n = Len(s)
    for i = 1 to n
        if Asc(Mid(s, i, 1)) > 127 then
            achou = true
            exit for
        end if
    end for
    if not achou then return s
    partes = []
    for i = 1 to n
        c = Mid(s, i, 1)
        a = Asc(c)
        if a < 128 then
            partes.Push(c)
        else if a >= 192 and a <= 255 then
            partes.Push(Mid(tabu, a - 191, 1))
        else if a = 338 then
            partes.Push("OE")
        else if a = 339 then
            partes.Push("oe")
        else if a >= 256 and a <= 383 then
            ' Latin estendido-A: aproxima pela letra base mais comum
            partes.Push(latinEstendido(a))
        else
            partes.Push(c)
        end if
    end for
    return partes.Join("")
end function

function latinEstendido(a as Integer) as String
    ' 256..383 (Ā ā Ă ă Ą ą Ć ć ... ž ſ)
    base = "AaAaAaCcCcCcCcDdDdEeEeEeEeEeGgGgGgGgHhHhIiIiIiIiIiJjJjKkkLlLlLlLlLlNnNnNnnNnOoOoOoOoRrRrRrSsSsSsSsTtTtTtUuUuUuUuUuUuWwYyYZzZzZzs"
    i = a - 255
    if i >= 1 and i <= Len(base) then return Mid(base, i, 1)
    return ""
end function

' minúsculas, sem acento, só letras e números separados por um espaço.
function norm(s as String) as String
    t = LCase(semAcento(s))
    if m.reNaoAlnum = invalid then m.reNaoAlnum = CreateObject("roRegex", "[^a-z0-9]+", "")
    t = m.reNaoAlnum.ReplaceAll(t, " ")
    return t.Trim()
end function

' ---- tempo ----
function dataBr(ts as Dynamic) as String
    n = iv(ts)
    if n <= 0 then return ""
    d = CreateObject("roDateTime")
    d.FromSeconds(n)
    d.ToLocalTime()
    return Right("0" + Str(d.GetDayOfMonth()).Trim(), 2) + "/" + Right("0" + Str(d.GetMonth()).Trim(), 2) + "/" + Str(d.GetYear()).Trim()
end function

function horaMinuto(ts as Dynamic) as String
    n = iv(ts)
    if n <= 0 then return ""
    d = CreateObject("roDateTime")
    d.FromSeconds(n)
    d.ToLocalTime()
    return Right("0" + Str(d.GetHours()).Trim(), 2) + ":" + Right("0" + Str(d.GetMinutes()).Trim(), 2)
end function

function horaAgora() as String
    return horaMinuto(nowSec())
end function

function anoAtual() as Integer
    d = CreateObject("roDateTime")
    d.ToLocalTime()
    return d.GetYear()
end function

' segundos -> "1:05:09" ou "5:09"
function hms(seg as Dynamic) as String
    n = iv(seg)
    if n < 0 then n = 0
    h = n \ 3600
    mi = (n mod 3600) \ 60
    s = n mod 60
    ss = Right("0" + Str(s).Trim(), 2)
    if h > 0 then return Str(h).Trim() + ":" + Right("0" + Str(mi).Trim(), 2) + ":" + ss
    return Str(mi).Trim() + ":" + ss
end function

function diasAte(ts as Dynamic) as Integer
    n = iv(ts)
    return Int((n - nowSec()) / 86400 + 0.9999)
end function

' ---- base64 (títulos do guia vêm assim) ----
function b64(s as String) as String
    if s = "" then return ""
    ba = CreateObject("roByteArray")
    ba.FromBase64String(s)
    return ba.ToAsciiString()
end function

' ---- JSON em arquivo ----
function lerJsonArq(caminho as String) as Dynamic
    t = ReadAsciiFile(caminho)
    if t = "" then return invalid
    return ParseJson(t)
end function

function gravarJsonArq(caminho as String, v as Object) as Boolean
    texto = FormatJson(v)
    fs = CreateObject("roFileSystem")
    ' Na thread da tela (Player, Store) o roFileSystem volta invalid: grava direto, sem trocar de arquivo.
    if fs = invalid then return WriteAsciiFile(caminho, texto)
    tmp = caminho + ".tmp"
    if not WriteAsciiFile(tmp, texto) then return false
    if fs.Exists(caminho) then fs.Delete(caminho)
    return fs.Rename(tmp, caminho)
end function

function cfg() as Object
    return m.global.config
end function

function idiomaEn() as Boolean
    return m.global.idioma = "en"
end function

' Capa: o painel às vezes manda texto vazio ou endereço sem http.
function urlImagem(v as Dynamic) as String
    s = sv(v).Trim()
    if s = "" then return ""
    if startsWith(LCase(s), "http") then return capaLeve(s)
    return ""
end function

' Capas do TMDB que o painel manda em 600x900 viram 342x513: o mesmo desenho, com cerca de 1/3 dos pixels para baixar e decodificar.
function capaLeve(s as String) as String
    return s.Replace("/t/p/w600_and_h900_bestv2/", "/t/p/w342/")
end function

function clampInt(v as Integer, mn as Integer, mx as Integer) as Integer
    if v < mn then return mn
    if v > mx then return mx
    return v
end function

' Resumo curto (sha1) de um texto, para nome de arquivo.
function hashCurto(s as String) as String
    ba = CreateObject("roByteArray")
    ba.FromAsciiString(s)
    d = CreateObject("roEVPDigest")
    d.Setup("sha1")
    return Left(d.Process(ba), 20)
end function
