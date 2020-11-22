using FritzHome
@test to_challenge("1234567z", "äbc") == "1234567z-9e224a41eeefa284df7bb0f26c2913e2"

# username = ENV["FRITZ_USERNAME"]
# fritz = FritzBox(username, ENV["FRITZ_PASSWORD"])
# devs = devices(fritz)
# temperature(fritz, devs[1])
# set_goal_temperature!(fritz, devs[1], 22)
# goal_temperature(fritz, devs[1])
# execute(fritz, "getbasicdevicestats", ain=device_id(devs[1]))
