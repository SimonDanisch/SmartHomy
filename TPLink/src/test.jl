
using Markdown
using JSServe.DOM
function smartass(session, request)

    img = DOM.img(src="https://alternative.me/icons/julia.png", width="30")

    dom = md"""# Julia Smarthome $img

    ## Light

    $(light)
    """
    return DOM.div(JSServe.MarkdownCSS, dom)
end

app = JSServe.Application(smartass, "0.0.0.0", 8081)

color_temperature(light)

brightness!(light, 10)

color_temperature!(light, 3000)
light.device.sent_lock.task

devices = query_devices()
light = collect(values(devices))[2]

function test_send(socket, address, value)
    message = Dict("brightness" => value)
    target = "smartlife.iot.smartbulb.lightingservice"
    cmd = "transition_light_state"
    request = Dict(target => Dict(cmd => message))
    task = @async read(socket)
    write(socket, encrypt(JSON3.write(request)))
    return task
end

address = light.device.ip
socket = connect(address)

t = test_send(socket, address, rand(1:100))
fetch(t)
