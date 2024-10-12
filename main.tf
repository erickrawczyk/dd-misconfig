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

# EC2 Instance
resource "aws_instance" "app_server" {
  ami           = "ami-0c94855ba95c71c99" # Amazon Linux 2 AMI in us-east-1
  instance_type = "t2.medium"
  key_name      = aws_key_pair.deployer.key_name

  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              # Install Docker
              amazon-linux-extras install docker -y
              service docker start
              usermod -a -G docker ec2-user

              sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
              sudo chmod +x /usr/local/bin/docker-compose
              docker-compose version

              # Install git
              yum install git -y

              # Clone the GitHub repository
              su ec2-user -c "git clone https://github.com/erickrawczyk/dd-misconfig.git /home/ec2-user/app"

              # Change directory to the app
              cd /home/ec2-user/app

              # Build and run Docker containers
              su ec2-user -c "cd /home/ec2-user/app && docker-compose up -d --build"
              EOF

  tags = {
    Name = "DataDogMisconfigDemo"
  }
}

# Save the private key to a local file
resource "local_file" "private_key_pem" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "private_key.pem"
  file_permission = "0600"
}
