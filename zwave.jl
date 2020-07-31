using PyCall
openzwave = pyimport("openzwave")

ZWaveNode = pyimport("openzwave.node").ZWaveNode
ZWaveValue = pyimport("openzwave.value").ZWaveValue
ZWaveScene = pyimport("openzwave.scene").ZWaveScene
ZWaveController = pyimport("openzwave.controller").ZWaveController
ZWaveNetwork = pyimport("openzwave.network").ZWaveNetwork
ZWaveOption = pyimport("openzwave.option").ZWaveOption
dispatcher = pyimport("pydispatch").dispatcher
time = pyimport("time")

function louie_network_started(network)
    printlnln("Hello from network : I'm started : homeid $(network.home_id) - $(network.nodes_count) nodes were found.")
end

function louie_network_failed(network)
    println("Hello from network : can't load :(.")
end

function louie_network_ready(network)
    println("Hello from network : I'm ready : $(network.nodes_count) nodes were found.")
    println("Hello from network : my controller is : $(network.controller)")
    dispatcher.connect(louie_node_update, ZWaveNetwork.SIGNAL_NODE)
    dispatcher.connect(louie_value_update, ZWaveNetwork.SIGNAL_VALUE)
end

function louie_node_update(network, node)
    println("Hello from node : $(node).")
end

function louie_value_update(network, node, value)
    println("Hello from value : $(value).")
end

#Create a network object
device = "/dev/ttyAMA0"
sniff = 300.0
#Define some manager options
options = ZWaveOption(
    device; config_path="/usr/local/etc/openzwave/",
    user_path=".homeassistant/", cmd_line=""
)
options.set_console_output(false)
options.lock()
network = ZWaveNetwork(options)

#We connect to the louie dispatcher
dispatcher.connect(louie_network_started, ZWaveNetwork.SIGNAL_NETWORK_STARTED)
dispatcher.connect(louie_network_failed, ZWaveNetwork.SIGNAL_NETWORK_FAILED)
dispatcher.connect(louie_network_ready, ZWaveNetwork.SIGNAL_NETWORK_READY)

network.start()

#We wait for the network.
println("***** Waiting for network to become ready : ")
break_loop = Ref(true)
task = @async while break_loop[]
    sleep(1.0)
    yield()
    time.sleep(1.0)
    py"print('-')"
    println("state: ", network.state)
end


for i in 1:90
    if network.state >= network.STATE_READY
        println("***** Network is ready")
        break
    else
        println("waiting: ", network.state)
        sleep(1.0)
    end
end

#We update the name of the controller
println("Update controller name")
network.controller.node.name = "Controller"

sleep(20)

task
#We update the location of the controller
println("Update controller location")
network.controller.node.location = "Hello location"


val = first(network.nodes[5].get_dimmers())[2]

idx = 2
network.nodes[idx].command_classes_as_string
network.nodes[idx].is_zwave_plus
network.nodes[idx].manufacturer_name
network.nodes[idx].product_name
network.nodes[idx].type
network.nodes[idx].test()
node = network.nodes[idx]
values = collect(node.get_values())
dim_id, dimmer = first(node.get_dimmers())
node.set_dimmer(dim_id, 99)
dim_id, dimmer = first(filter(x-> x[2].label == "Level", values))
dimmer.data = 99

setable = filter(x-> !x[2].is_read_only, values)
setable

id, heateco = filter(x-> x[2].label == "Heat", values)[1]
heateco.data
heateco.data = 21.0
heateco.refresh()
heateco.data

network.nodes[2].values[id].data



py"help"(heateco.set_change_verified)

for (id, elem) in setable
    if (elem.min, elem.max) == (8, 28)
        println(elem.label)
    end
end
dimmer_id, dimmer = collect()[1]
dimmer_id, dimmer = collect(node.get_dimmers())[1]
node.set_dimmer(dimmer_id, Cint(100))

py"$(node).set_dimmer($dimmer_id, 100)"

node.get_dimmer_level(dimmer_id)
