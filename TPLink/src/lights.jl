const COLOR_TEMPERATURE_RANGES = Dict(
    "LB130" => 2500..9000,
    "LB120" => 2700..6500,
    "LB230" => 2500..9000,
    "KB130" => 2500..9000,
    "KL130" => 2500..9000,
    "KL120(EU)" => 2700..6500,
    "KL120(US)" => 2700..5000,
)

function extract_response(response)
    haskey(response, LIGHT_DEVICE_KEY) || return
    info = response[LIGHT_DEVICE_KEY]
    haskey(info, "transition_light_state") || return
    return info["transition_light_state"]
end

function extract_response(response, key)
    info = extract_response(response)
    info === nothing && return
    if key == "color"
        return HSV(info.hue, info.saturation / 100, info.brightness / 100)
    end
    return get(info, key, nothing)
end

function light_command(success_callback, device::DeviceConnection, message)
    request = Dict(LIGHT_DEVICE_KEY => Dict("transition_light_state" => message))
    send(success_callback, device, request)
end

function Light(device::DeviceConnection, sysinfo)
    ls = sysinfo.light_state
    light = if haskey(ls, "dft_on_state")
        ls.dft_on_state
    else
        ls
    end

    brightness = Bool(sysinfo.is_dimmable) ? ReadWrite : Readonly
    color_temp = Bool(sysinfo.is_variable_color_temp) ? ReadWrite : Readonly
    color = Bool(sysinfo.is_color) ? ReadWrite : Readonly
    crange = COLOR_TEMPERATURE_RANGES[sysinfo["model"]]

    light_device = Light{DeviceConnection}(
        device,

        sysinfo[:alias],
        ls.on_off,

        (light.brightness => 0..100) => brightness,
        (light.color_temp => crange) => color_temp,
        HSV(light.hue, light.saturation, light.brightness) => color
    )

    for attribute in (:color_temperature, :brightness, :toggle, :color)
        on_command(light_device, attribute) do output, value
            light_command(device, attribute, output, value)
        end
    end

    return light_device
end

function light_command(device::DeviceConnection, name::Symbol, output::Observable, value)
    message_key = if name == :color_temperature
        "color_temp"
    elseif name == :brightness
        "brightness"
    elseif name == :toggle
        "on_off"
    elseif name == :color
        "color"
    end
    message = if name == :color
        Dict("hue" => value.h, "saturation" => value.s * 100.0, "brightness" => value.v * 100.0)
    elseif name == :toggle
        Dict(message_key => Int(value))
    else
        Dict(message_key => value)
    end
    light_command(device, message) do response
        # Exctract the value we set!
        value_on_device = extract_response(response, message_key)
        if value != value_on_device
            error("Device didn't accept updating $(name) for value $(value). Got: $(value_on_device)")
        end
        # Finally, set the devices value!
        output[] = value
    end
end
