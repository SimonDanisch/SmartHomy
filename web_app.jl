#!/usr/bin/env julia

@info("loading packages")
cd(@__DIR__)
using PyCall, Markdown, JSServe
using SmartHomy
using TPLink
using SmartHomy: start!, stop!, AbstractLight, AbstractPlug, μg_m³
using JSServe.DOM
using JSServe: @js_str
using FileWatching

asset(dirs...) = JSServe.Asset(joinpath(@__DIR__, dirs...))
js_asset(dirs...) = JSServe.Asset(JSServe.dependency_path(dirs...))

@info("loading sensors")
include("./Sensors/hm3301.jl")
include("./Sensors/lywsd02.jl")
include("./Sensors/dht_sensors.jl")
include("./Sensors/groove_sensors.jl")


airquality = GroveAirQualitySensor(0)
lightsensor = GroveLightSensor(6)

sensors = [HM3301(), LYWSD02("E7:2E:00:B0:70:A4"), DHTSensor(22), airquality, lightsensor]
foreach(start!, sensors)

@info("Query TPLink")
devices = TPLink.query_devices()

if length(devices) != 4
    devices = TPLink.query_devices()
end

lights = filter(x-> x isa AbstractLight, devices)
plugs = filter(x-> x isa AbstractPlug, devices)

struct Card
    title::String
    children
end

include("webpage.jl")
reload_task = @async while isfile("webpage.jl")
    fm = FileWatching.watch_file("webpage.jl")
    try
        @info("reloading webpage")
        include("webpage.jl")
    catch e
        @warn "couldnt reload" execption=e
    end
end

@info("starting server")
app = JSServe.Application(smarthomy, "0.0.0.0", 8081)
@info("all started!")
wait(app.server_task[])
