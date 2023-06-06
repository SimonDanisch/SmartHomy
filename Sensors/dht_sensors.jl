using SmartHomy: TemperatureHumiditySensor
using SmartHomy: set!, device
using Unitful, PyCall

const DHT = pyimport("adafruit_dht")

struct DHTConnection
    device
end

function DHTSensor(channel::Int)
    device = DHT.DHT22(channel)
    return TemperatureHumiditySensor(DHTConnection(device))
end

function Base.read!(sensor::TemperatureHumiditySensor{DHTConnection})
    temperature = device(sensor).device.temperature
    humidity = device(sensor).device.humidity
    set!(sensor, :temperature, temperature * Unitful.°C)
    set!(sensor, :humidity, humidity * Unitful.percent)
    return
end
