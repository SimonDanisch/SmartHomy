__precompile__(false)
module TPLink

using Sockets, JSON3, Observables, Colors
using SmartHomy
using SmartHomy: AbstractLight, AbstractPlug, DeviceQueue, DropAllButLast, Readonly, ReadWrite, on_command
import SmartHomy: Light, Plug
using IntervalSets

include("comm.jl")
include("lights.jl")
include("plugs.jl")

end
