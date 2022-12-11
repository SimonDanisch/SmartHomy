using FritzHome
@test to_challenge("1234567z", "äbc") == "1234567z-9e224a41eeefa284df7bb0f26c2913e2"

quote
    username = ENV["FRITZ_USERNAME"]
    fritz = FritzHome.FritzBox(username, ENV["FRITZ_PASSWORD"])
    devs = FritzHome.devices(fritz)
    FritzHome.temperature(fritz, devs[2])
    foreach(dev-> FritzHome.set_goal_temperature!(fritz, dev, 21), devs)
    set_goal_temperature!(fritz, devs[1], 22)
    FritzHome.goal_temperature(fritz, devs[3])
    FritzHome.execute(fritz, "getbasicdevicestats", ain=FritzHome.device_id(devs[1]))
end
