struct Light{T} <: AbstractLight
    device::T

    name::Attribute{String}
    toggle::Attribute{Bool}

    target_temperature::RangedAttribute{Float64}
    measured_temperature::RangedAttribute{Float64}
end
