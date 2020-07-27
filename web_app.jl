using PyCall, Markdown, JSServe
push!(Base.LOAD_PATH, @__DIR__)
using SmartHomy
using TPLink
using SmartHomy: start!, stop!, AbstractLight, AbstractPlug, μg_m³
using JSServe.DOM

include("hm3301.jl")
include("lywsd02.jl")
include("dht_sensors.jl")

sensors = [HM3301(), LYWSD02("E7:2E:00:B0:70:A4"), DHTSensor(22, 22)]
Threads.@spawn begin
    foreach(start!, sensors)
end

foreach(stop!, sensors)
foreach(start!, sensors)

devices = TPLink.query_devices()

lights = filter(x-> x isa AbstractLight, devices)
plugs = filter(x-> x isa AbstractPlug, devices)


struct Card
    title::String
    children
end

function JSServe.jsrender(s::JSServe.Session, card::Card)
    return JSServe.jsrender(s, DOM.div(
        DOM.h1(card.title, class="text-3xl font-bold"),
        card.children...,
        class = "rounded-lg p-2 shadow-lg flex flex-col text-center items-center m-2"
    ))
end

function smarthomy(session, request)
    img = DOM.img(src="https://raw.githubusercontent.com/JuliaLang/julia-logo-graphics/b5551ca7946b4a25746c045c15fbb8806610f8d0/images/old-style/three-balls.svg",
        width="40", class="inline-block")

    header = DOM.div(DOM.h1("Julia Smarthome", class="text-3xl font-bold"), img, class="flex-row flex justify-center")
    sensor_card = Card("Sensors", sensors)
    light_card = Card("Lights", lights)
    plug_card = Card("Plugs", plugs)
    dom = DOM.div(header, sensor_card, light_card, plug_card, class="md:text-2xl")
    return DOM.div(JSServe.Asset(JSServe.dependency_path("styled.css")),
                   JSServe.TailwindCSS, JSServe.MarkdownCSS, dom)
end

app = JSServe.Application(smarthomy, "0.0.0.0", 8081)
