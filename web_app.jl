#!/usr/bin/env julia

@info("loading packages")
cd(@__DIR__)
using Revise
using PyCall, Markdown, JSServe
using SmartHomy
using SmartHomy: start!, stop!, AbstractLight, AbstractPlug, μg_m³
using TPLink
using JSServe
using FileWatching
import JSServe.TailwindDashboard as D
using Shelly

asset(dirs...) = JSServe.Asset(joinpath(@__DIR__, dirs...))

@info("Query TPLink")
devices = TPLink.query_devices()

lights = filter(x-> x isa AbstractLight, devices)
plugs = filter(x-> x isa AbstractPlug, devices)

device1 = Shelly.Device("192.168.178.29")
device2 = Shelly.Device("192.168.178.30")
device3 = Shelly.Device("192.168.178.51")
plugs = [device1, device2, device3]

include("webpage.jl")
# reload_task = @async while isfile("webpage.jl")
#     fm = FileWatching.watch_file("webpage.jl")
#     try
#         @info("reloading webpage")
#         include("webpage.jl")
#     catch e
#         @warn "couldnt reload" execption=e
#     end
# end

@info("starting server")
app = JSServe.Server(smarthomy, "0.0.0.0", 8081)
@info("all started!")
wait(app.server_task[])

# using Shelly
# using PyCall
# pyShelly = PyCall.pyimport("pyShelly")

# shelly = pyShelly.pyShelly()
# shelly.start()
# shelly.discover()
