using SmartHomy: TemperatureHumiditySensor
using SmartHomy: set!, device
using Unitful

const Lywsd02Client = pyimport("lywsd02").Lywsd02Client

struct LYWSD02Connection
    client
end

# LYWSD02("E7:2E:00:B0:70:A4")
function LYWSD02(mac_address::String)
    client = Lywsd02Client(mac_address)
    conn = LYWSD02Connection(client)
    return TemperatureHumiditySensor(conn)
end

function Base.read!(sensor::TemperatureHumiditySensor{LYWSD02Connection})
    io = device(sensor)
    set!(sensor, :temperature, io.client.temperature * Unitful.°C)
    set!(sensor, :humidity, io.client.humidity * Unitful.percent)
    return
end
