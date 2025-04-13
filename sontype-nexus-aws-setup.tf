provider "aws" {
  region = "us-east-1"  # Adjust region if necessary
}

resource "aws_instance" "nexus" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI (adjust for your region)
  instance_type = "t3.medium"  # Adjust instance type as per your requirements
  key_name      = "your-ssh-key"  # Replace with your SSH key name

  # Security Group to allow access to port 8081 (Nexus)
  security_group = aws_security_group.nexus_sg.name

  # Instance metadata and user data to run the Nexus installation script
  user_data = <<-EOF
              #!/bin/bash
              set -e
              # Update system and install Java
              sudo apt update && sudo apt upgrade -y
              sudo apt install openjdk-8-jdk -y

              # Create nexus user
              sudo adduser --disabled-password --gecos "" nexus
              sudo usermod -aG sudo nexus

              # Download and install Nexus
              cd /opt
              sudo wget https://download.sonatype.com/nexus/3/nexus-3.70.4-02-java8-unix.tar.gz
              sudo tar -xvzf nexus-3.70.4-02-java8-unix.tar.gz
              sudo mv nexus-3.70.4-02 nexus
              sudo chown -R nexus:nexus /opt/nexus

              # Configure Nexus to run as nexus user
              echo 'run_as_user="nexus"' | sudo tee /opt/nexus/bin/nexus.rc

              # Create systemd service for Nexus
              cat <<EOF2 | sudo tee /etc/systemd/system/nexus.service
              [Unit]
              Description=Nexus Repository Manager
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
              EOF2

              # Reload systemd and enable Nexus service
              sudo systemctl daemon-reexec
              sudo systemctl daemon-reload
              sudo systemctl enable nexus
              sudo systemctl start nexus

              # Print default admin password and Nexus URL
              echo -e "\n✅ Nexus is installed and running on port 8081."
              sudo cat /opt/sonatype-work/nexus3/admin.password
              echo -e "\n💡 Access Nexus at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8081"
              EOF

  # Tags for the instance
  tags = {
    Name = "Nexus Server"
  }
}

# Security group to allow HTTP and HTTPS access
resource "aws_security_group" "nexus_sg" {
  name        = "nexus_sg"
  description = "Allow HTTP, HTTPS, and SSH access"

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "nexus_public_ip" {
  value = aws_instance.nexus.public_ip
  description = "The public IP address of the Nexus server"
}
