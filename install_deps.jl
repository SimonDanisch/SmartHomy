
run(`sudo apt install libgpiod2`)
run(`pip3 install lywsd02 smbus2 grovepi adafruit-circuitpython-lis3dh adafruit-circuitpython-dht`)
# install service with
# sudo systemd enable homy.service
# sudo systemd start homy.service
# view logs with  journalctl -u homy.service -f
write("/etc/systemd/system/homy.service", """
[Unit]
Description=SmartHomy - Open Source Smarthome
After=network.target

[Service]
User=pi
ExecStart=/usr/local/bin/julia --project=/home/pi/SmartHomy /home/pi/SmartHomy/web_app.jl
Restart=on-failure

[Install]
WantedBy=multi-user.target
""")
