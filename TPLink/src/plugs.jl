function Plug(device::DeviceConnection, sysinfo)
    plug = Plug{DeviceConnection}(device, sysinfo[:alias], sysinfo.relay_state)
    on_command(plug, :toggle) do output, value
        message = Dict("state" => Int(value))
        request = Dict("system" => Dict("set_relay_state" => message))
        send(device, request) do response
            response === nothing && return
            output[] = value
        end
    end
    return plug
end
