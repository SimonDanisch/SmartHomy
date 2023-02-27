struct ShellyDevice
    device::PyObject
end

function Plug(shelly::PyObject, settings)
    device = ShellyDevice(shelly)
    plug = Plug{ShellyDevice}(device, settings["name"], settings["relays"][1]["ison"])
    SmartHomy.on_command(plug, :toggle) do output, value
        try
            shelly.relay(0; turn=value)
            output[] = value
        catch e
            @warn "error when turning plug $(value ? "on" : "off")." exception = e
        end
    end
    return plug
end

function Device(ip::String)
    device = SHELLY_LIB[].Shelly(ip)
    settings = device.settings()
    type = settings["device"]["type"]
    if occursin("SHPLG", type)
        return Plug(device, settings)
    else
        error("Device type not supported")
    end
end
