using SmartHomy: TemperatureHumiditySensor
using SmartHomy: set!, device
using Unitful

const DHT = pyimport("Adafruit_DHT")

struct DHTConnection
    type::Int
    channel::Int
end

function DHTSensor(type::Int, channel::Int)
    conn = DHTConnection(type, channel)
    return TemperatureHumiditySensor(conn)
end

function Base.read!(sensor::TemperatureHumiditySensor{DHTConnection})
    conn = device(sensor)
    humidity, temperature = DHT.read_retry(conn.type, conn.channel)
    set!(sensor, :temperature, temperature * Unitful.°C)
    set!(sensor, :humidity, humidity * Unitful.percent)
    return
end
