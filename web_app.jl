#!/usr/bin/env julia

@info("loading packages")
cd(@__DIR__)
using PyCall, Markdown, JSServe
ENV["JULIA_DEBUG"] = JSServe
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
tp_plugs = filter(x-> x isa AbstractPlug, devices)

device1 = Shelly.Device("192.168.178.29")
device2 = Shelly.Device("192.168.178.30")
device3 = Shelly.Device("192.168.178.51")
plugs = [device1, device2, device3, tp_plugs...]

include("webpage.jl");


@info("starting server")
app = JSServe.Server(smarthomy, "0.0.0.0", 8888)
app.proxy_url = "http://mini-server.fritz.box:8888"
route!(app, "/" => smarthomy)
@info("all started!")


l = lights[1]
