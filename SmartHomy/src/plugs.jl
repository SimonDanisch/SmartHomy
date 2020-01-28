struct Plug{T} <: AbstractPlug
    device::T
    name::Attribute{String}
    toggle::Attribute{Bool}
end
