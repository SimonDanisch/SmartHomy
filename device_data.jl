@enum UpdateType Queued DropWhileBusy DropAllButLast

struct DeviceData
    type::UpdateType
    task::Task
    channel::Channel
    processing::Threads.Atomic{Bool}
end

isprocessing(x::DeviceData) = x.processing[]

function DeviceData(type::UpdateType)
    channel = type == Queued ? Channel() : Channel(1)
    processing = Threads.Atomic{Bool}(false)
    task = Threads.@spawn while true
        # While we have tasks, execute them!
        f = take!(channel)
        try
            processing[] = true
            Base.invokelatest(f)
        catch e
            rethrow(e)
        finally
            processing[] = false
        end
    end
    return DeviceData(type, task, channel, processing)
end

function Base.put!(new_task::Function, x::DeviceData)
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
