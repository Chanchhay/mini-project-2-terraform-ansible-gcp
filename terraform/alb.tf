
# =====================================
# ALB Security Group
# =====================================
resource "aws_security_group" "alb" {
  name_prefix = "devops-mini-alb-"
  description = "ALB HTTP access"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "devops-mini-alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = toset(var.allowed_ssh_cidrs)

  security_group_id = aws_security_group.alb.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "alb_to_targets" {
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = aws_vpc.main.cidr_block
}

# Allow ALB to access Traefik
resource "aws_vpc_security_group_ingress_rule" "traefik_from_alb" {
  security_group_id            = aws_security_group.servers.id
  referenced_security_group_id = aws_security_group.alb.id

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
}

# =====================================
# AWS Application Load Balancer
# =====================================
resource "aws_lb" "main" {
  name               = "devops-mini-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb.id]

  subnets = [
    aws_subnet.public[0].id,
    aws_subnet.public[1].id
  ]

  enable_deletion_protection = false

  tags = {
    Name = "devops-mini-alb"
  }
}

# =====================================
# SonarQube Target Group
# =====================================
resource "aws_lb_target_group" "sonarqube" {
  name        = "devops-mini-sonar"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    path                = "/ping"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "sonarqube" {
  target_group_arn = aws_lb_target_group.sonarqube.arn
  target_id        = aws_instance.servers["sonarqube"].id
  port             = 80
}

# =====================================
# Nexus Target Group
# =====================================
resource "aws_lb_target_group" "nexus" {
  name        = "devops-mini-nexus"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    path                = "/ping"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "nexus" {
  target_group_arn = aws_lb_target_group.nexus.arn
  target_id        = aws_instance.servers["nexus"].id
  port             = 80
}

# =====================================
# ALB HTTP Listener
# =====================================
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "No matching application host"
      status_code  = "404"
    }
  }
}

# =====================================
# SonarQube Listener Rule
# =====================================
resource "aws_lb_listener_rule" "sonarqube" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sonarqube.arn
  }

  condition {
    host_header {
      values = [var.sonarqube_domain]
    }
  }
}

# =====================================
# Nexus Listener Rule
# =====================================
resource "aws_lb_listener_rule" "nexus" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nexus.arn
  }

  condition {
    host_header {
      values = [var.nexus_domain]
    }
  }
}


# =====================================
# Jenkins Target Group
# =====================================
resource "aws_lb_target_group" "jenkins" {
  name        = "devops-mini-jenkins"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    path                = "/ping"
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# =====================================
# Register Jenkins EC2 in Target Group
# =====================================
resource "aws_lb_target_group_attachment" "jenkins" {
  target_group_arn = aws_lb_target_group.jenkins.arn
  target_id        = aws_instance.servers["jenkins"].id
  port             = 80
}

# =====================================
# Jenkins Host-Based Routing
# =====================================
resource "aws_lb_listener_rule" "jenkins" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 5

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins.arn
  }

  condition {
    host_header {
      values = [var.jenkins_domain]
    }
  }
}

