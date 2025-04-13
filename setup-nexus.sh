#!/bin/bash

set -e

# Update system and install Java
echo "Updating packages and installing Java..."
sudo apt update && sudo apt upgrade -y
sudo apt install openjdk-8-jdk -y


# Create nexus user
echo "Creating nexus user..."
sudo adduser --disabled-password --gecos "" nexus
sudo usermod -aG sudo nexus

# Download and install Nexus
echo "Downloading and installing Nexus..."
cd /opt
sudo wget https://download.sonatype.com/nexus/3/nexus-3.70.4-02-java8-unix.tar.gz
sudo tar -xvzf nexus-3.70.4-02-java8-unix.tar.gz
sudo mv nexus-3.70.4-02 nexus
sudo chown -R nexus:nexus /opt/nexus


# Configure Nexus to run as nexus user
echo 'run_as_user="nexus"' | sudo tee /opt/nexus/bin/nexus.rc

# Create systemd service
echo "Creating systemd service for Nexus..."
cat <<EOF | sudo tee /etc/systemd/system/nexus.service
[Unit]
Description=nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
User=nexus
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable nexus
echo "Enabling and starting Nexus service..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable nexus
sudo systemctl start nexus

# Print default admin password
echo -e "\n✅ Nexus is installed and running on port 8081"
echo -e "🔐 Default admin password:"
sudo cat /opt/sonatype-work/nexus3/admin.password
echo -e "\n💡 Access Nexus at: http://<your-ec2-ip>:8081\n"