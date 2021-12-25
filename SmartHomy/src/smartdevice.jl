@enum AccesPattern Readonly ReadWrite

struct AttributeField{T, VR}
    input::Observable{T}
    attribute::Observable{T}
    value_range::VR
    access::AccesPattern
    unit::String
end

function AttributeField(attribute::Observable{T}, vrange::VR, access, unit) where {T, VR}
    return AttributeField{T, VR}(Observable(attribute[]), attribute, vrange, access, unit)
end

function Base.getindex(attribute::AttributeField)
    return attribute.attribute[]
end

function Base.setindex!(attribute::AttributeField{T}, value) where T
    if is_readonly(attribute)
        throw(ArgumentError("Cannot set $(value) for $(attribute_name). Attribute is readonly for $(typeof(device))"))
    else
        if checkvalue(attribute, value)
            val_converted = convert(eltype(attribute), value)
            attribute.input[] = val_converted
        else
            throw(ArgumentError("Value $(value) for $(attribute_name) is not in range $(attribute.value_range) for $(typeof(device))"))
        end
    end
end

Base.eltype(::AttributeField{T}) where {T} = T
is_readonly(x::AttributeField) = x.access == Readonly

const Attribute{T} = AttributeField{T, Nothing}
const RangedAttribute{T} = AttributeField{T, Interval{:closed, :closed, T}}
const OptionalAttribute{T} = Union{Attribute{T}, Nothing}
const RangedOptionalAttribute{T} = Union{RangedAttribute{T}, Nothing}

function Base.convert(::Type{Attribute{T}}, value) where {T}
    AttributeField(Observable(convert(T, value)), nothing, ReadWrite, "")
end

function Base.convert(::Type{Attribute{T}}, value::Pair{Y, AccesPattern}) where {T, VR, Y}
    AttributeField(Observable(convert(T, value[1])), nothing, value[2], "")
end

function Base.convert(::Type{AttributeField{T, VR}}, value::Pair{Y, VR}) where {T, VR, Y}
    AttributeField(Observable(convert(T, value[1])), value[2], ReadWrite, "")
end

function Base.convert(::Type{AttributeField{T, VR}}, value_fields::Pair{Pair{Y, VR}, AccesPattern}) where {T, VR, Y}
    (value, range), access = value_fields
    value_conv = convert(T, value)
    AttributeField(Observable(value_conv), range, access, "")
end

function Base.convert(::Type{AttributeField{T, VR}}, value_fields::Pair{Y, Pair{VR, AccesPattern}}) where {T, VR, Y}
    value, (range, access) = value_fields
    value_conv = convert(T, value)
    AttributeField(Observable(value_conv), range, access, "")
end

function Base.convert(::Type{Attribute{T}}, value::Pair{Y, String}) where {T, VR, Y}
    value_conv = convert(T, value[1])
    AttributeField(Observable(value_conv), nothing, ReadWrite, value[2])
end

function set!(device::SmartDevice, attribute::Symbol, value)
    getfield(device, attribute).attribute[] = value
end

function checkvalue(attribute::AttributeField{T, VR}, value) where {T, VR}
    return value in attribute.value_range
end

function checkvalue(attribute::Attribute, value)
    return true
end

function Base.setproperty!(device::SmartDevice, attribute_name::Symbol, value)
    if !hasproperty(device, attribute_name)
        error("Device $(typeof(device)) does not have attribute: $(attribute_name)")
    else
        attribute = getfield(device, attribute_name)
        if attribute === nothing
            throw(ArgumentError("Value $(value) for $(attribute_name) is not supported for $(typeof(device))"))
        else
            attribute[] = value
        end
    end
end

function Base.getproperty(device::SmartDevice, attribute_name::Symbol)
    if !hasproperty(device, attribute_name)
        error("Device $(typeof(device)) does not have attribute: $(attribute_name)")
    else
        attribute = getfield(device, attribute_name)
        if attribute isa Attribute
            return attribute.attribute
        else
            return attribute
        end
    end
end

function on_command(set_callback, device::SmartDevice, attribute_name::Symbol)
    attribute = getfield(device, attribute_name)
    on(attribute.input) do value
        set_callback(attribute.attribute, value)
    end
end

function all_attributes(device::T) where {T<:SmartDevice}
    result = Dict{Symbol, AttributeField}()
    for field in fieldnames(T)
        attribute = getfield(device, field)
        attribute isa AttributeField && (result[field] = attribute)
    end
    return result
end

function attribute_widget(attribute::Attribute{String})
    return DOM.div(attribute.attribute)
end

function attribute_widget(attribute::Attribute{Bool})
    is_on = attribute.attribute
    style = "p-1 m-1 rounded pr-2 pl-2 shadow-md hover:bg-gray-500 hover:text-gray-100"
    on_off_button = JSServe.Button(is_on[] ? "ON" : "OFF", class=style)
    on(is_on) do val
        on_off_button.content[] = val ? "ON" : "OFF"
    end
    on(on_off_button) do val
        attribute[] = !is_on[]
    end
    return on_off_button
end

function attribute_widget(attribute::RangedAttribute{T}) where T <: Number
    start, stop = extrema(attribute.value_range)
    tick = if T <: Integer
        (stop - start) / 100
    else
        (stop - start) ÷ 100
    end
    slider = JSServe.Slider(start:tick:stop, class="custom-range")
    slider[] = attribute[]
    on(slider) do val
        attribute[] = val
    end
    return DOM.div(slider, class="w-64")
end

attribute_render(session::JSServe.Session, x) = JSServe.jsrender(session, x)

function to_superscript(x)
    superscripts = Dict(
        '.' => '⋅',
        '0' => '⁰',
        '1' => '¹',
        '2' => '²',
        '3' => '³',
        '4' => '⁴',
        '5' => '⁵',
        '6' => '⁶',
        '7' => '⁷',
        '8' => '⁸',
        '9' => '⁹',
        '+' => '⁺',
        '-' => '⁻')

    return join(map(x-> superscripts[x], collect(x)), "")

end

function attribute_render(session::JSServe.Session, x::Observable{T}) where T <: Quantity
    str = map(x) do x
        unit_str = replace(string(Unitful.unit(x)), r"\^([-\d]*)" => (x)-> to_superscript(x[2:end]))
        return DOM.div(string(round(x.val, digits=2), unit_str), style="white-space: nowrap;")
    end
    return JSServe.jsrender(session, str)
end

function attribute_render(::JSServe.Session, x::Observable{T}) where T <: Colorant
    return DOM.div(style=map(x-> "background-color: #" * Colors.hex(x), x), class="h-10 w-10 rounded-lg shadow-lg m-1")
end

function JSServe.jsrender(session::JSServe.Session, attribute::AttributeField)
    if is_readonly(attribute)
        return attribute_render(session, attribute.attribute)
    else
        attribute_widget(attribute)
    end
end

function JSServe.jsrender(session::JSServe.Session, device::SmartDevice)
    attributes = all_attributes(device)
    title = DOM.div(get(attributes, :name, "NoName"), class="text-3xl font-bold")
    delete!(attributes, :name)
    fields = map(collect(attributes)) do (k, v)
        DOM.div(string(k, ": "), DOM.div(attribute_render(session, v), class="text-gray-500"), class="flex flex-nowrap flex-row justify-between")
    end
    return DOM.div(title, fields..., class="flex flex-col items-left")
end

function show_unit(x)
    string(round(x.val, digits=2), )
end
