
function JSServe.jsrender(s::JSServe.Session, card::Card)
    return JSServe.jsrender(s, DOM.div(
        DOM.h1(card.title, class="text-4xl font-bold"),
        card.children...,
        class = "min-w-min rounded-lg shadow-md px-5 mx-5"
    ))
end

function smarthomy(session, request)
    @info("setting last session")
    global last_session = session
    img = DOM.img(src=asset("julia-logo.svg"),  class="inline-block h-12")

    header = DOM.div(DOM.h1("Homy", class="text-4xl font-bold"), img, class="flex-row flex justify-center")
    sensor_card = Card("Sensors", sensors)
    light_card = Card("Lights", lights)
    plug_card = Card("Plugs", plugs)
    class = "grid auto-cols-max grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4"
    sensor_grid = DOM.div(sensor_card, light_card, plug_card, class=class)
    dom = DOM.div(header, sensor_grid, class="text-3xl w-full h-full")
    return DOM.div(asset("WebApp", "slider.css"), JSServe.TailwindCSS, JSServe.MarkdownCSS, dom)
end

if @isdefined(last_session)
    @info("reloading last session")
    JSServe.evaljs(last_session, js"location.reload(true)")
end
