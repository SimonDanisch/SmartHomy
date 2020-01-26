
function JSServe.jsrender(plug::AbstractPlug)
    on_off_button = JSServe.Button(name(plug) * ": " * (is_on(plug) ? "ON" : "OFF"))
    on(plug.is_on) do val
        on_off_button.content[] = name(plug) * ": " * (val ? "ON" : "OFF")
    end
    on(on_off_button.value) do val
        if plug.is_on[]
            turn_off!(plug)
        else
            turn_on!(plug)
        end
    end
    return on_off_button
end
