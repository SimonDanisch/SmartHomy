module TPLink

using Sockets, JSON3, Observables, Colors
using IntervalSets
using SmartHomy

using SmartHomy: AbstractLight, AbstractPlug, DeviceQueue, DropAllButLast, Readonly, ReadWrite, on_command
import SmartHomy: Light, Plug

include("comm.jl")
include("lights.jl")
include("plugs.jl")

end
