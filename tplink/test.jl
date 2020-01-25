
devices = query_devices()
light = collect(values(devices))[2]

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

brightness!(light, 20)
color_temperature!(light, 3000)
