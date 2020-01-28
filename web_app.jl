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
Threads.@spawn foreach(start!, sensors)

start!(sensors[1])
stop!(sensors[1])
sensors[1].data.task[]

# foreach(stop!, sensors)
devices = TPLink.query_devices()
lights = filter(x-> x isa AbstractLight, devices)
plugs = filter(x-> x isa AbstractPlug, devices)
function smartass(session, request)
    img = DOM.img(src="https://alternative.me/icons/julia.png", width="30")

    dom = md"""# Julia Smarthome $img
    ## Sensors

    ---

    ## Lights

    $(lights)
    ---

    ## Plugs

    $(plugs)
    ---
    """
    return DOM.div(JSServe.MarkdownCSS, dom)
end

app = JSServe.Application(smartass, "0.0.0.0", 8081)
