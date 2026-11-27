data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd*/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "devops" {
  key_name   = "${var.project_name}-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

locals {
  machines = {
    jenkins = {
      subnet_index = 0
      disk_size    = 40
    }
    sonarqube = {
      subnet_index = 1
      disk_size    = 40
    }
    nexus = {
      subnet_index = 0
      disk_size    = 50
    }
  }
}

resource "aws_instance" "servers" {
  for_each = local.machines

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[each.value.subnet_index].id
  vpc_security_group_ids      = [aws_security_group.servers.id]
  key_name                    = aws_key_pair.devops.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = each.value.disk_size
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "${var.project_name}-${each.key}"
    Role = each.key
  }
}