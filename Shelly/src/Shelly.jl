module Shelly

using PyCall
using SmartHomy
import SmartHomy: Light, Plug, SmartDevice

const SHELLY_LIB = Ref{Any}(nothing)

function __init__()
    SHELLY_LIB[] = PyCall.pyimport("ShellyPy")
end

include("devices.jl")

end
