using SmartHomy: SensorData, AbstractSensor
import SmartHomy: units

const Lywsd02Client = pyimport("lywsd02").Lywsd02Client

struct LYWSD02Connection
    client
end

# LYWSD02("E7:2E:00:B0:70:A4")
function LYWSD02Connection(mac_address::String)
    client = Lywsd02Client(mac_address)
    return LYWSD02(client, SensorData())
end

function Base.read!(sensor::TemperatureHumiditySensor{LYWSD02Connection})
    io = connection(sensor)
    SmartHomy.set!(sensor, :temperature, io.client.temperature)
    SmartHomy.set!(sensor, :humidity, io.client.humidity)
    return
end
