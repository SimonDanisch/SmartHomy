__precompile__(false)
module TPLink

using Sockets, JSON3, Observables, Colors
using SmartHomy
using SmartHomy: AbstractLight, AbstractPlug, DeviceQueue, DropAllButLast
import SmartHomy: brightness, color_temperature, set_color_temperature!, set_brightness!, set_color!, turn_off!, turn_on!, supports, temperature_range, name
import Colors: color

include("comm.jl")
include("lights.jl")
include("plugs.jl")

function SmartHomy.name(device::Union{Plug, Light})
    return device.sysinfo[:alias]
end

end
