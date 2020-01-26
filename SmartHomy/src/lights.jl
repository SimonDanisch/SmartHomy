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

set_color_temperature!(light::AbstractLight, value::Number) = error("Not Implemented")
color_temperature(light::AbstractLight) = error("Not Implemented")

function color_temperature!(light::AbstractLight, value::Number)
    if !supports(light, color_temperature)
        error("Light does not support setting color_temperature")
    end
    start, stop = temperature_range(light)
    if value >= start && value <= stop
        set_color_temperature!(light, value)
    else
        throw(ArgumentError("color_temperature needs to be between $(start)..$(stop)"))
    end
end

set_color!(light::AbstractLight, value::Colorant) = error("Not Implemented")
Colors.color(light::AbstractLight) = error("Not Implemented")

function color!(light::AbstractLight, value::Colorant)
    if !supports(light, color)
        error("Light does not support setting color!")
    end
    set_color!(light, value)
end

turn_on!(light::AbstractLight) = error("Not Implemented")
turn_off!(light::AbstractLight) = error("Not Implemented")
is_on(light::AbstractLight) = false


function JSServe.jsrender(light::AbstractLight)
    on_off = JSServe.Button(is_on(light) ? "ON" : "OFF", class="btn btn-primary")
    on(on_off.value) do val
        if on_off.content[] == "ON"
            turn_off!(light)
            on_off.content[] = "OFF"
        else
            turn_on!(light)
            on_off.content[] = "ON"
        end
    end

    elements = Any[DOM.div(name(light)), on_off]

    if supports(light, color_temperature)
        start, stop = temperature_range(light)
        temp = JSServe.Slider((start+1):10:(stop-1), class="custom-range")
        temp[] = color_temperature(light)
        on(temp) do val
            color_temperature!(light, val)
        end
        el = DOM.div(DOM.p("color_temperature: ", temp.value), temp)
        push!(elements, el)
    end

    if supports(light, brightness)
        brightness_s = JSServe.Slider(1:5:100)
        brightness_s[] = brightness(light)
        on(brightness_s) do val
            brightness!(light, val)
        end
        el = DOM.div(DOM.p("brightness: ", brightness_s.value), brightness_s)
        push!(elements, el)
    end
    return DOM.div(elements...)
end
