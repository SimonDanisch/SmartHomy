struct Light <: AbstractLight
    device::DeviceConnection
    sysinfo::Dict
    supports_brightness::Bool
    supports_color_temperature::Bool
    supports_color::Bool
    temperature_range::Tuple{Int, Int}

    is_on::Observable{Bool}
    color::Observable{HSV{Float32}}
    brightness::Observable{Int}
    color_temperature::Observable{Int}
end

function Light(device::DeviceConnection, sysinfo)
    ls = sysinfo.light_state
    Light(
        device,
        Dict(sysinfo),
        sysinfo.is_dimmable,
        sysinfo.is_variable_color_temp,
        sysinfo.is_color,
        (2700, 6500),
        Observable(Bool(ls.on_off)),
        Observable(HSV(ls.hue, ls.saturation, ls.brightness)),
        Observable(ls.brightness),
        Observable(ls.color_temp)
    )
end

function extract_response(response)
    haskey(response, LIGHT_DEVICE_KEY) || return
    info = response[LIGHT_DEVICE_KEY]
    haskey(response, "transition_light_state") || return
    return response["transition_light_state"]
end

function extract_response(response, key)
    info = extract_response(response)
    info === nothing && return
    return get(info, key, nothing)
end

function Sockets.send(success_callback, light::Light, message)
    request = Dict(LIGHT_DEVICE_KEY => Dict("transition_light_state" => message))
    send(success_callback, light.device, request)
end

function supports(light::Light, func::typeof(brightness))
    return light.supports_brightness
end

function supports(light::Light, func::typeof(color_temperature))
    return light.supports_color_temperature
end

function supports(light::Light, func::typeof(color))
    return light.supports_color
end

function temperature_range(light::Light)
    return light.temperature_range
end

function brightness(light::Light)
    return light.brightness[]
end

function set_brightness!(light::Light, value::Number)
    send(light, Dict("brightness" => value)) do response
        value = extract_response(response, :brightness)
        value === nothing && return # Seems like we failed!
        light.brightness[] = value
    end
end

function color_temperature(light::Light)
    return light.color_temperature[]
end

function set_color_temperature!(light::Light, value::Number)
    send(light, Dict("color_temp" => value)) do response
        value = extract_response(response, :color_temp)
        value === nothing && return # Seems like we failed!
        light.color_temperature[] = value
    end
end

function Colors.color(light::Light)
    return light.color[]
end

function set_color!(light::Light, value::Colorant)
    hsv = convert(HSV, value)
    msg = Dict("hue" => hsv.h, "saturation" => hsv.s * 100.0, "brightness" => hsv.v * 100.0)
    send(light, msg) do response
        info = extract_response(response)
        info === nothing && return # Seems like we failed!
        light.color[] = HSV(hsv.hue, hsv.s / 100, hsv.brightness / 100)
    end
    return
end

function turn_on!(light::Light)
    send(light, Dict("on_off" => 1)) do response
        response === nothing && return # Seems like we failed!
        light.is_on[] = true
    end
    return
end

function turn_off!(light::Light)
    send(light, Dict("on_off" => 0)) do response
        response === nothing && return # Seems like we failed!
        light.is_on[] = false
    end
    return
end

is_on(light::AbstractLight) = light.is_on[]
