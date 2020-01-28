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
    result = AttributeField[]
    for field in fieldnames(T)
        attribute = getfield(device, field)
        attribute isa AttributeField && push!(result, attribute)
    end
    return result
end

function attribute_widget(attribute::Attribute{String})
    return DOM.div(attribute.attribute)
end

function attribute_widget(attribute::Attribute{Bool})
    is_on = attribute.attribute
    on_off_button = JSServe.Button(is_on[] ? "ON" : "OFF")
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
    return slider
end

function JSServe.jsrender(session::JSServe.Session, attribute::AttributeField)
    if is_readonly(attribute)
        return JSServe.jsrender(session, attribute.attribute)
    else
        attribute_widget(attribute)
    end
end

function JSServe.jsrender(session::JSServe.Session, device::SmartDevice)
    return DOM.div(all_attributes(device))
end
