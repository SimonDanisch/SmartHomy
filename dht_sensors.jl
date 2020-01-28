using SmartHomy: SensorData, AbstractSensor
import SmartHomy: units

const DHT = pyimport("Adafruit_DHT")

struct DHTConnection
    type::Int
    channel::Int
end

DHTSensor(type::Int, channel::Int) = DHTSensor(type, channel, SensorData())

function Base.read!(sensor::TemperatureHumiditySensor{DHTConnection})
    io = connection(sensor)
    humidity, temperature = DHT.read_retry(io.type, io.channel)
    set!(sensor, :temperature, temperature)
    set!(sensor, :humidity, humidity)
    return
end
