using PyCall
using JSServe, Observables
using Base: RefValue
using Markdown
using Colors

using JSServe.DOM

include("sensors.jl")
include("lights.jl")
include("device_data.jl")
include("hm3301.jl")
include("lywsd02.jl")
include("dht_sensors.jl")
include("tplink.jl")

hm3301 = HM3301()
lywsd02 = LYWSD02("E7:2E:00:B0:70:A4")
dht = DHTSensor(22, 22)

stop!(dht)
stop!(lywsd02)
stop!(hm3301)

start!(dht)
start!(lywsd02)
start!(hm3301)

light = TPLinkLight("192.168.0.6")

turn_on!(light)
brightness!(light, 50)
brightness!(light, 100)
temperature!(light, 2800)

function smartass(session, request)

    img = DOM.img(src="https://alternative.me/icons/julia.png", width="30")

    dom = md"""# Julia Smarthome $img
    ## HM3301:

    $hm3301
    ---
    ## Mi Temp:

    $(lywsd02)
    ---
    ## dht:

    $(dht)

    ---

    ## Light

    $(light)
    """
    return DOM.div(JSServe.MarkdownCSS, dom)
end

app = JSServe.Application(smartass, "0.0.0.0", 8081)
