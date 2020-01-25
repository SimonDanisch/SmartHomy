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

function Sockets.send(success_callback, light::Light, message)
    target = "smartlife.iot.smartbulb.lightingservice"
    cmd = "transition_light_state"
    request = Dict(target => Dict(cmd => message))
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
    send(light, Dict("brightness" => value)) do
        light.brightness[] = value
    end
end

function color_temperature(light::Light)
    return light.color_temperature[]
end

function set_color_temperature!(light::Light, value::Number)
    send(light, Dict("color_temp" => value)) do
        light.color_temperature[] = value
    end
end

function Colors.color(light::Light)
    return light.color[]
end

function set_color!(light::Light, value::Colorant)
    hsv = convert(HSV, value)
    msg = Dict("hue" => hsv.h, "saturation" => hsv.s * 100.0, "brightness" => hsv.v * 100.0)
    send(light, msg) do
        light.color[] = hsv
    end
    return
end

function turn_on!(light::Light)
    send(light, Dict("on_off" => 1)) do
        light.is_on[] = true
    end
    return
end

function turn_off!(light::Light)
    send(light, Dict("on_off" => 0)) do
        light.is_on[] = false
    end
    return
end

is_on(light::AbstractLight) = light.is_on[]
