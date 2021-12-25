#https://build.julialang.org/#/
#https://s3.amazonaws.com/julialangnightlies/assert_pretesting/linux/armv7l/1.6/julia-a8393c4a3b-linuxarmv7l.tar.gz
run(`sudo apt install libgpiod2`)
run(`pip3 install lywsd02 smbus2 grovepi adafruit-circuitpython-lis3dh adafruit-circuitpython-dht`)
#=
git clone https://github.com/Seeed-Studio/grove.py
cd grove.py
# Python2
sudo pip install .
# Python3
sudo pip3 install .
=#

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


read("/etc/systemd/system/homy.service", String) |> println

read("/etc/systemd/system/syncthing.service", String) |> println

write("/etc/systemd/system/syncthing.service", """
[Unit]
Description=Syncthing - Open Source Continuous File Synchronization for %I
Documentation=man:syncthing(1)
After=network.target

[Service]
User=s
ExecStart=/usr/bin/syncthing -no-restart -logflags=0
Restart=on-failure
RestartSec=5
SuccessExitStatus=3 4
RestartForceExitStatus=3 4

# Hardening
ProtectSystem=full
PrivateTmp=true
SystemCallArchitectures=native
MemoryDenyWriteExecute=true
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
""")
