abstract type AbstractSensor end

# The interface

struct SensorData
    poll_interval::Float64
    isrunning::RefValue{Bool}
    data::Observable{Dict{Symbol, Float64}}
end

function SensorData(poll_interval::Number=2.0)
    return SensorData(poll_interval, Ref(false), Observable(Dict{Symbol, Float64}()))
end

function set!(sensor::AbstractSensor, name::Symbol, value)
    data_observable(sensor)[][name] = value
end

"""
    sensor_data(sensor::AbstractSensor)::SensorData
Returns the sensor data struct
"""
function sensor_data(sensor::AbstractSensor)
    return sensor.data
end

"""
    poll_interval(sensor::AbstractSensor)
Returns the polling interval in Seconds
"""
function poll_interval(sensor::AbstractSensor)
    return sensor_data(sensor).poll_interval
end

"""
    isrunning(sensor::AbstractSensor)
Returns if true if the sensor polling loop is running
"""
function isrunning(sensor::AbstractSensor)
    return sensor_data(sensor).isrunning[]
end

"""
    read!(sensor::AbstractSensor)

Reads and updates the current sensor data!
Gets updated by read!(sensor)

Note: Expected to block as long as it takes to read the sensor!
"""
function Base.read!(sensor::AbstractSensor)::Dict{Symbol, Float64}
    error("read! not implemented for $(typeof(sensor)).
          This is part of the basic sensor interface and needs to be implemented")
end

"""
    current_data(sensor::AbstractSensor)
Returns the current data of sensor.
Gets updated by read!(sensor)

Note: Should be copied before mutating!
"""
function data_observable(sensor::AbstractSensor)::Observable{Dict{Symbol, Float64}}
    return sensor_data(sensor).data
end

"""
    units(sensor::AbstractSensor)::NTuple{N, Symbol}
Returns either one string, if sensor has the same units for all data.
Returns Dict{Symbol, String} for a unit for each field.
"""
function units(sensor::AbstractSensor)::Union{String, Dict{Symbol, String}}
    return "none"
end

function start!(sensor::AbstractSensor)
    # No need to start, if running already
    isrunning(sensor) && return
    sensor_data(sensor).isrunning[] = true
    observable = data_observable(sensor)
    @async while isrunning(sensor)
        Base.read!(sensor)
        # notify observable
        Base.invokelatest(setindex!, observable, observable[])
        sleep(poll_interval(sensor))
    end
end

function stop!(sensor::AbstractSensor)
    sensor_data(sensor).isrunning[] = false
    return
end

function JSServe.jsrender(sensor::AbstractSensor)
    data = data_observable(sensor)
    fields = collect(keys(data[]))
    sensor_units = units(sensor)
    elements = map(fields) do field
        DOM.div(map(data) do d
            u = sensor_units isa String ? sensor_units : sensor_units[field]
            return string(field, ": ", round(d[field], digits=3), u)
        end)
    end
    return DOM.div(elements...)
end
