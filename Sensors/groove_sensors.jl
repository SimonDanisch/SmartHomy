using SmartHomy: LightIntensitySensor, AirQualitySensor, device, set!

include("adc.jl")

struct GroveLightSensor
    channel::Int
    adc::ADC
end

GroveLightSensor(channel::Int) = LightIntensitySensor(GroveLightSensor(channel, ADC()))

function Base.read!(sensor::LightIntensitySensor{GroveLightSensor})
    dev = device(sensor)
    set!(sensor, :intensity, read(dev.adc, dev.channel))
end

struct GroveAirQualitySensor
    channel::Int
    adc::ADC
end

GroveAirQualitySensor(channel::Int) = AirQualitySensor(GroveAirQualitySensor(channel, ADC()))

function Base.read!(sensor::AirQualitySensor{GroveAirQualitySensor})
    dev = device(sensor)
    value = read(dev.adc, dev.channel)
    set!(sensor, :pollution, value)
end
