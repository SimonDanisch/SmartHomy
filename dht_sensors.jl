const DHT = pyimport("Adafruit_DHT")

struct DHTSensor <: AbstractSensor
    type::Int
    channel::Int
    data::SensorData
end

DHTSensor(type::Int, channel::Int) = DHTSensor(type, channel, SensorData())

function Base.read!(sensor::DHTSensor)
    humidity, temperature = DHT.read_retry(sensor.type, sensor.channel)
    set!(sensor, :temperature, temperature)
    set!(sensor, :humidity, humidity)
    return
end

function units(sensor::DHTSensor)
    return Dict(:temperature => "C", :humidity => "%")
end
