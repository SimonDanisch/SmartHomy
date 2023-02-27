
smarthomy = App(title="SmartHomy") do
    img = DOM.img(src=asset("julia-logo.svg"),  class="inline-block h-12")
    header = DOM.div(DOM.h1("Homy", class="text-4xl font-bold"), img, class="flex-row flex justify-center")
    light_card = D.Card(lights)
    plug_card = D.Card(plugs)
    sensor_grid = D.FlexRow(light_card, plug_card)
    dom = DOM.div(header, sensor_grid, class="text-3xl w-full h-full")
    return DOM.div(asset("WebApp", "slider.css"), JSServe.TailwindCSS, JSServe.MarkdownCSS, dom)
end
