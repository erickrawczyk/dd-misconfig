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
  ami           = "ami-06b21ccaeff8cd686" # Amazon Linux 2 AMI in us-east-1
  instance_type = "t2.medium"
  key_name      = aws_key_pair.deployer.key_name

  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              # Set environment variable for Datadog API Key
              export DD_API_KEY=${var.dd_api_key}

              # Update the system
              yum update -y

              # Install required tools
              yum install -y git python3 postgresql postgresql-server postgresql-devel

              # Initialize and start the PostgreSQL database
              postgresql-setup initdb
              systemctl enable postgresql
              systemctl start postgresql

              # Change to the postgres user to configure the database
              sudo -u postgres psql -c "CREATE DATABASE mydatabase;"
              sudo -u postgres psql -c "CREATE USER datadog WITH PASSWORD 'datadog';"
              sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE mydatabase TO datadog;"

              # Install pip and Python requirements
              python3 -m ensurepip
              pip3 install --upgrade pip

              # Navigate to the home directory of ec2-user
              cd /home/ec2-user

              # Clone the GitHub repository
              git clone https://github.com/erickrawczyk/dd-misconfig.git app

              # Navigate to the app directory
              cd app

              # Install Python requirements
              pip3 install -r requirements.txt

              # Download the Datadog Agent installation script
              DD_API_KEY=${DD_API_KEY} DD_INSTALL_ONLY=true bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script_agent7.sh)"

              # Enable and start the Datadog Agent
              systemctl enable datadog-agent
              systemctl start datadog-agent

              # Start the Python application with ddtrace
              ddtrace-run python3 app.py # Adjust the command according to the app's structure
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
