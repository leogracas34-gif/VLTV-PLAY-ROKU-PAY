' VLTV Play - Roku | Ponto de entrada.
sub Main(args as Dynamic)
    screen = CreateObject("roSGScreen")
    porta = CreateObject("roMessagePort")
    screen.SetMessagePort(porta)

    g = screen.GetGlobalNode()
    cfg = ParseJson(ReadAsciiFile("pkg:/config.json"))
    if cfg = invalid then cfg = {}
    g.addFields({
        config: cfg,
        idioma: "en",
        sessao: {},
        lic: {},
        info: {},
        parceiroNome: "",
        ehParceiro: false,
        parentalLiberado: false,
        visual: {}
    })

    cena = screen.CreateScene("MainScene")
    screen.Show()

    while true
        msg = Wait(0, porta)
        if Type(msg) = "roSGScreenEvent" then
            if msg.IsScreenClosed() then return
        end if
    end while
end sub
