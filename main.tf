
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

data "aws_vpc" "main" {
  id = "vpc-0b7142d91a515e4a5"
}

data "aws_subnet" "public" {
  id = "subnet-0b96297f57520226f"
}


resource "aws_security_group" "devops" {
  name   = "devops-project-sg"
  vpc_id = data.aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["119.13.156.76/32"]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["119.13.156.76/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-project-sg"
  }
}

resource "aws_instance" "servers" {
  count = 3

  ami = "ami-048c1a9eb63a67eed"
  instance_type               = "m7i-flex.large"
  subnet_id                   = data.aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.devops.id]
  key_name                    = "devops-key"
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = count.index == 0 ? "jenkins-server" : "worker-${count.index}"
  }
}

output "server_public_ips" {
  value = aws_instance.servers[*].public_ip
}