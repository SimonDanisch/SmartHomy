
smarthomy = App(title="SmartHomy") do
    img = DOM.img(src=asset("julia-logo.svg"),  class="inline-block h-12")
    header = DOM.div(DOM.h1("Homy", class="text-lg font-bold"), img, class="flex-row flex justify-center")
    light_card = D.Card(lights)
    plug_card = D.Card(DOM.div(plugs...; class="flex flex-wrap"))
    sensor_grid = DOM.div(light_card, plug_card; class="flex flex-wrap")
    dom = DOM.div(header, sensor_grid, class="text-base w-full h-full")
    return DOM.div(Asset("site.css"), asset("WebApp", "slider.css"), JSServe.TailwindCSS, JSServe.MarkdownCSS, dom)
end;
route!(app, "/" => smarthomy)
