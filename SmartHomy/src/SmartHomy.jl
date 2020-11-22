module SmartHomy

using JSServe
using Observables
using Base: RefValue
using Markdown
using Colors
using JSServe.DOM
using IntervalSets
using Unitful

abstract type SmartDevice end

abstract type AbstractLight <: SmartDevice end
abstract type AbstractPlug <: SmartDevice end
abstract type AbstractSensor <: SmartDevice end

include("device_locks.jl")
include("smartdevice.jl")
include("lights.jl")
include("plugs.jl")
include("sensors.jl")

end
