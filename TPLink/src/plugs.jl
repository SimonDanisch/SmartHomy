struct Plug <: AbstractPlug
    device::DeviceConnection
    sysinfo::Dict
    is_on::Observable{Bool}
end

function Plug(device::DeviceConnection, sysinfo)
    Plug(device, Dict(sysinfo), Observable(sysinfo.relay_state == 1))
end

function Sockets.send(success_callback, plug::Plug, message)
    request = Dict("system" => Dict("set_relay_state" => message))
    send(success_callback, plug.device, request)
end

function turn_on!(plug::Plug)
    send(plug, Dict("state" => 1)) do response
        response === nothing && return
        plug.is_on[] = true
    end
    return
end

function turn_off!(plug::Plug)
    send(plug, Dict("state" => 0)) do response
        response === nothing && return
        plug.is_on[] = false
    end
    return
end
