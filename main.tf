provider "aws" {
  region = "us-east-1"
}

# Generate an SSH key pair if you don't have one
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Store the public key in AWS
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Security group to allow SSH and HTTP access
resource "aws_security_group" "instance_sg" {
  name        = "instance-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allows SSH from anywhere; restrict as needed
  }

  ingress {
    from_port   = 80
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allows HTTP access to your app
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Create a subnet
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a" # Replace as needed
  map_public_ip_on_launch = true
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# Route Table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# Associate the Route Table with the Subnet
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.rt.id
}

variable "dd_api_key" {
  description = "Datadog API Key"
  type        = string
  sensitive   = true
}

# EC2 Instance
resource "aws_instance" "app_server" {
  count         = 10
  ami           = "ami-0866a3c8686eaeeba"
  instance_type = "t2.medium"
  key_name      = aws_key_pair.deployer.key_name

  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              # Set environment variables
              export DD_API_KEY="${var.dd_api_key}"

              # Update the system
              sudo apt update -y
              sudo apt upgrade -y

              # Install required tools
              sudo apt install -y git python3 python3-pip postgresql postgresql-contrib

              # Start PostgreSQL service
              sudo systemctl enable postgresql
              sudo systemctl start postgresql

              # Initialize and start the PostgreSQL database
              sudo -u postgres psql -c "CREATE DATABASE mydatabase;"
              sudo -u postgres psql -c "CREATE USER datadog WITH PASSWORD 'datadog';"
              sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE mydatabase TO datadog;"

              # Install pip and Python requirements
              sudo -H pip3 install --upgrade pip

              # Navigate to the home directory of the default user
              cd /home/ubuntu

              # Clone the GitHub repository
              git clone https://github.com/erickrawczyk/dd-misconfig.git app

              # Navigate to the app directory
              cd app/misconfigbase
              git checkout WIP

              # Install Python requirements
              pip3 install -r requirements.txt

              # Download the Datadog Agent installation script
              DD_API_KEY="${var.dd_api_key}" DD_INSTALL_ONLY=true bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script_agent7.sh)"

              # Enable and start the Datadog Agent
              sudo systemctl enable datadog-agent
              sudo systemctl start datadog-agent

              # Create a systemd service for the app
              echo "[Unit]
              Description=Misconfigbase Application Service
              After=network.target postgresql.service

              [Service]
              User=ubuntu
              WorkingDirectory=/home/ubuntu/app/misconfigbase
              ExecStart=/usr/bin/ddtrace-run /usr/bin/python3 app.py
              Restart=always
              Environment=\"DD_API_KEY=${var.dd_api_key}\"

              [Install]
              WantedBy=multi-user.target
              " | sudo tee /etc/systemd/system/app.service

              # Reload systemd to pick up the new service
              sudo systemctl daemon-reload

              # Enable the service to start on boot
              sudo systemctl enable app.service

              # Start the application service
              sudo systemctl start app.service
              EOF

  tags = {
    Name = "DataDogMisconfigDemo-${count.index}"
  }
}

# Save the private key to a local file
resource "local_file" "private_key_pem" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "private_key.pem"
  file_permission = "0600"
}
