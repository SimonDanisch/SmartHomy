
struct GroveLightSensor
    channel::Int
    adc
end

GroveLightSensor(channel::Int) = GroveLightSensor(channel, ADC())
Base.read(light::GroveLightSensor) = light.adc.read(light.channel)
