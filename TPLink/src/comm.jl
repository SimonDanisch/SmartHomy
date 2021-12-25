#=
Implementation based on
https://github.com/softScheck/tplink-smartplug
softScheck/tplink-smartplug is licensed under the
Apache License 2.0
A permissive license whose main conditions require preservation of copyright and license notices. Contributors provide an express grant of patent rights. Licensed works, modifications, and larger works may be distributed under different terms and without source code.
==#

const LIGHT_DEVICE_KEY = "smartlife.iot.smartbulb.lightingservice"

function encrypt(message::String)
    key = -85 % UInt8
    io = IOBuffer()
    write(io, ntoh(UInt32(length(message))))
    for char in message
        key = xor(key, UInt8(char))
        write(io, key)
    end
    return take!(io)
end

function decrypt(encrypted::Vector{UInt8})
    key = -85 % UInt8
    result = UInt8[]
    for byte in encrypted
        char = xor(key, byte)
        key = byte
        push!(result, char)
    end
    return String(result)
end

function send_encrypted(sock, msg::Dict)
    write(sock, encrypt(JSON3.write(msg)))
end

struct DeviceConnection
    ip::Sockets.InetAddr{IPv4}
    sent_lock::DeviceQueue
end

DeviceConnection(address) = DeviceConnection(address, DeviceQueue(DropAllButLast))

function Sockets.send(success_callback, device::DeviceConnection, message)
    put!(device.sent_lock) do
        socket = Sockets.connect(device.ip)
        try
            send_encrypted(socket, message)
            len_byte = read(socket, UInt32)
            if len_byte == 0
                # Some devices seem to use len byte 0, and sent a \0 to show if done
                data = readuntil(socket, UInt8(0))
            else
                data = read(socket, Int(ntoh(len_byte)))
            end
            close(socket)
            success_callback(JSON3.read(decrypt(data)))
        catch e
            @info "error" exception=e
        finally
            close(socket)
        end
    end
end

function create_device(device, info)
    sysinfo = nothing
    if haskey(info, "system") && haskey(info["system"], "get_sysinfo")
        sysinfo = info["system"]["get_sysinfo"]
        if haskey(sysinfo, "type")
            type = sysinfo["type"]
        elseif haskey(sysinfo, "mic_type")
            type = sysinfo["mic_type"]
        else
            error("Unknown device")
        end
    else
        error("Faulty response")
    end
    type = lowercase(type)
    if occursin("smartplug", type)
        return haskey(sysinfo, "children") ? :strip : Plug(device, sysinfo)
    elseif occursin("smartbulb", type)
        return Light(device, sysinfo)
    else
        error("Uknown device: $(type)")
    end
end

function query_devices()
    socket = UDPSocket()
    try
        # Somehow, at least on windows, I need to send first,
        # which gets a permission error, but if I don't sent, I can't set enable_broadcast
        send(socket, ip"255.255.255.255", 9999, "bla\n")
    catch e
    end

    Sockets.setopt(socket; enable_broadcast=true)

    queries = Dict(
        "system" => Dict("get_sysinfo" => nothing),
        "emeter" => Dict("get_realtime" => nothing),
        "smartlife.iot.dimmer" => Dict("get_dimmer_parameters" => nothing),
        "smartlife.iot.common.emeter" => Dict("get_realtime" => nothing),
        LIGHT_DEVICE_KEY => Dict("get_light_state" => nothing),
    )

    query_str = JSON3.write(queries)
    query_encrypted = encrypt(query_str)[5:end]

    for i in 1:5
        send(socket, ip"255.255.255.255", 9999, query_encrypted)
        sleep(0.5)
    end

    devices = Dict{Any, Any}()
    @async begin
        while socket.status in (Sockets.StatusInit, Sockets.StatusOpen)
            try
                ip, data = recvfrom(socket)
                # TPLinkDevice(ip)
                device = DeviceConnection(ip)
                devices[ip] = create_device(device, JSON3.read(decrypt(data)))
            catch e
                # TODO handle errors other than end of file (which is expected)
                Base.showerror(stdout, e)
                Base.show_backtrace(stdout, Base.catch_backtrace())
                break
            end
        end
        println("YAY DONE!")
    end
    lastlen = length(devices)
    while true
        sleep(6.0)
        if lastlen == length(devices)
            println("DONE")
            break
        else
            println("found new device")
            lastlen = length(devices)
        end
    end
    close(socket)
    return collect(values(devices))
end
