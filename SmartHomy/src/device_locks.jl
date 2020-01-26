@enum UpdateType Queued DropWhileBusy DropAllButLast

struct DeviceQueue
    type::UpdateType
    task::Task
    channel::Channel
    processing::Threads.Atomic{Bool}
end

isprocessing(x::DeviceQueue) = x.processing[]

function DeviceQueue(type::UpdateType)
    channel = type == Queued ? Channel() : Channel(1)
    processing = Threads.Atomic{Bool}(false)
    task = @async while true
        # While we have tasks, execute them!
        f = take!(channel)
        try
            processing[] = true
            Base.invokelatest(f)
        catch e
            @info "Error in queue" exception=e
        finally
            processing[] = false
        end
    end
    return DeviceQueue(type, task, channel, processing)
end

function Base.put!(new_task::Function, x::DeviceQueue)
    if x.type == DropWhileBusy
        if !isready(x.channel) # channel already full
            if !isprocessing(x) # only put new channel, if not processing
                put!(x.channel, new_task)
            end
        end
    elseif x.type == DropAllButLast
        if !isready(x.channel) # channel has no values, so we good to put
            put!(x.channel, new_task)
        else # values in channel
            # we're not processing last item, so we need to remove it!
            take!(x.channel) # drop the last latest value
            put!(x.channel, new_task) # and update it to the newest
        end
    else
        put!(x.channel, new_task)
    end
end

dq = DeviceQueue(DropAllButLast)

for i in 1:5
    put!(dq) do
        tstart = time()
        sleep(0.5)
        println(i)
    end
end
