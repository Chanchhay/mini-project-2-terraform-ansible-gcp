resource "aws_security_group" "servers" {
  name_prefix = "${var.project_name}-servers-"
  description = "Security group for DevOps servers"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-servers-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh_local" {
  for_each = toset(var.allowed_ssh_cidrs)

  security_group_id = aws_security_group.servers.id

  description = "SSH from approved public IP"
  cidr_ipv4   = each.value
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "ssh_internal" {
  security_group_id = aws_security_group.servers.id

  description                  = "SSH between project EC2 instances"
  referenced_security_group_id = aws_security_group.servers.id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "outbound" {
  security_group_id = aws_security_group.servers.id

  description = "Allow outbound IPv4 traffic"
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

# Allow internal communication between lab EC2 instances
resource "aws_vpc_security_group_ingress_rule" "internal_ci_http" {
  security_group_id            = aws_security_group.servers.id
  referenced_security_group_id = aws_security_group.servers.id

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80

  description = "Private EC2 to EC2 HTTP for CI integrations"
}