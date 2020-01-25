const Lywsd02Client = pyimport("lywsd02").Lywsd02Client

struct LYWSD02 <: AbstractSensor
    client
    data::SensorData
end

# LYWSD02("E7:2E:00:B0:70:A4")
function LYWSD02(mac_address::String)
    client = Lywsd02Client(mac_address)
    return LYWSD02(client, SensorData())
end

function Base.read!(sensor::LYWSD02)
    set!(sensor, :temperature, sensor.client.temperature)
    set!(sensor, :humidity, sensor.client.humidity)
    return sensor.data
end

function units(sensor::LYWSD02)
    return Dict(:temperature => "C", :humidity => "%")
end
