const pyHS100 = pyimport("pyHS100")
const Discover = pyHS100.Discover
const SmartBulb = pyHS100.SmartBulb
const SmartPlug = pyHS100.SmartPlug

# devices = Discover.discover()

struct TPLinkLight <: AbstractLight
    bulb::PyObject# ::SmartBulb
end

function TPLinkLight(ip::String)
    TPLinkLight(SmartBulb(ip))
end


function supports(light::TPLinkLight, func::typeof(brightness))
    return light.bulb.is_dimmable
end

function supports(light::TPLinkLight, func::typeof(temperature))
    return light.bulb.is_variable_color_temp
end

function supports(light::TPLinkLight, func::typeof(color))
    return light.bulb.is_color
end

function temperature_range(light::TPLinkLight)
    return light.bulb.valid_temperature_range
end

function brightness(light::TPLinkLight)
    return light.bulb.brightness
end

function set_brightness!(light::TPLinkLight, value::Number)
    light.bulb.brightness = value
    return
end

function temperature(light::TPLinkLight)
    return light.bulb.color_temp
end

function set_temperature!(light::TPLinkLight, value::Number)
    light.bulb.color_temp = value
    return
end

function Colors.color(light::TPLinkLight)
    return HSV((light.bulb.hsv ./ (1, 100, 100))...)
end

function set_color!(light::TPLinkLight, value::Colorant)
    hsv = convert(HSV, value)
    light.bulb.hsv = (hsv.h, hsv.s * 100.0, hsv.v * 100.0)
    return
end

function turn_on!(light::TPLinkLight)
    light.bulb.state = "ON"
    return
end

function turn_off!(light::TPLinkLight)
    light.bulb.state = "OFF"
    return
end

is_on(light::AbstractLight) = light.bulb.state == "ON"

function encrypt(string::String)
    key = -85 % UInt8
    return map(collect(string)) do char
        byte = UInt8(char)
        encrypted = key ^ byte
        key = byte
        return encrypted
    end
end

function send_encrypted(sock, msg::Dict)
    write(sock, encrypt(JSON3.write(msg)))
end
