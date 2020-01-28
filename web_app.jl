using PyCall, Markdown, JSServe
push!(Base.LOAD_PATH, @__DIR__)
using SmartHomy
using TPLink
using SmartHomy: AbstractPlug, AbstractLight, AbstractSensor, start!, stop!
using JSServe.DOM

devices = TPLink.query_devices()

lights = filter(x-> x isa AbstractLight, devices)
plugs = filter(x-> x isa AbstractPlug, devices)


using SmartHomy: SensorData

include("hm3301.jl")
include("lywsd02.jl")
include("dht_sensors.jl")



sensors = [HM3301(), LYWSD02("E7:2E:00:B0:70:A4"), DHTSensor(22, 22)]
Threads.@spawn foreach(start!, sensors)
# foreach(stop!, sensors)

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
