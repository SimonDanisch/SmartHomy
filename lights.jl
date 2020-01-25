abstract type AbstractLight end

supports(light::AbstractLight, func) = false

temperature_range(light::AbstractLight) = error("Not Implemented")

set_brightness!(light::AbstractLight, value::Number) = error("Not Implemented")
brightness(light::AbstractLight) = error("Not Implemented")

function brightness!(light::AbstractLight, value::Number)
    if !supports(light, brightness)
        error("Light does not support setting brightness")
    end
    if value >= 0.0 && value <= 100.0
        set_brightness!(light, value)
    else
        throw(ArgumentError("Brightness needs to be between 0..100"))
    end
end

set_temperature!(light::AbstractLight, value::Number) = error("Not Implemented")
temperature(light::AbstractLight) = error("Not Implemented")

function temperature!(light::AbstractLight, value::Number)
    if !supports(light, temperature)
        error("Light does not support setting temperature")
    end
    start, stop = temperature_range(light)
    if value >= start && value <= stop
        set_temperature!(light, value)
    else
        throw(ArgumentError("Temperature needs to be between $(start)..$(stop)"))
    end
end

set_color!(light::AbstractLight, value::Colorant) = error("Not Implemented")
Colors.color(light::AbstractLight) = error("Not Implemented")

function color!(light::AbstractLight, value::Colorant)
    if !supports(light, color)
        error("Light does not support setting color!")
    end
    set_temperature!(light, value)
end

turn_on!(light::AbstractLight) = error("Not Implemented")
turn_off!(light::AbstractLight) = error("Not Implemented")
is_on(light::AbstractLight) = false


function JSServe.jsrender(light::AbstractLight)
    light_update_queue = DeviceData(DropAllButLast)

    on_off = JSServe.Button(is_on(light) ? "ON" : "OFF", class="btn btn-primary")
    on(on_off.value) do val
        if is_on(light)
            put!(light_update_queue) do
                turn_off!(light)
                on_off.content[] = "OFF"
            end
        else
            put!(light_update_queue) do
                turn_on!(light)
                on_off.content[] = "ON"
            end
        end
    end

    elements = Any[on_off]

    if supports(light, temperature)
        start, stop = temperature_range(light)
        temp = JSServe.Slider(start:100:stop, class="custom-range")
        temp[] = temperature(light)
        on(temp) do val
            put!(light_update_queue) do
                temperature!(light, val)
            end
        end
        el = DOM.div(DOM.p("temperature: ", temp.value), temp)
        push!(elements, el)
    end

    if supports(light, brightness)
        brightness_s = JSServe.Slider(0:5:100)
        brightness_s[] = brightness(light)
        on(brightness_s) do val
            put!(light_update_queue) do
                brightness!(light, val)
            end
        end
        el = DOM.div(DOM.p("brightness: ", brightness_s.value), brightness_s)
        push!(elements, el)
    end
    return DOM.div(elements...)
end

Threads.nthreads()
