struct Light{T} <: AbstractLight
    device::T

    name::Attribute{String}
    toggle::Attribute{Bool}

    brightness::RangedOptionalAttribute{Int}
    color_temperature::RangedOptionalAttribute{Int}
    color::OptionalAttribute{HSV{Float32}}
end
