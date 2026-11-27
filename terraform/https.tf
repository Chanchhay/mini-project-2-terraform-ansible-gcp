
# -----------------------------------------
# Find existing imported ACM Certificates
# -----------------------------------------
data "aws_acm_certificate" "jenkins" {
  domain      = var.jenkins_domain
  statuses    = ["ISSUED"]
  types       = ["IMPORTED"]
  most_recent = true
}

data "aws_acm_certificate" "sonarqube" {
  domain      = var.sonarqube_domain
  statuses    = ["ISSUED"]
  types       = ["IMPORTED"]
  most_recent = true
}

data "aws_acm_certificate" "nexus" {
  domain      = var.nexus_domain
  statuses    = ["ISSUED"]
  types       = ["IMPORTED"]
  most_recent = true
}

# -----------------------------------------
# HTTPS inbound access to ALB
# -----------------------------------------
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  for_each = toset(var.allowed_ssh_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from approved lab IP"

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = each.value
}

# -----------------------------------------
# ALB HTTPS Listener
# -----------------------------------------
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = data.aws_acm_certificate.jenkins.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "No matching HTTPS host"
      status_code  = "404"
    }
  }
}

# -----------------------------------------
# Additional SNI Certificates
# -----------------------------------------
resource "aws_lb_listener_certificate" "sonarqube" {
  listener_arn    = aws_lb_listener.https.arn
  certificate_arn = data.aws_acm_certificate.sonarqube.arn
}

resource "aws_lb_listener_certificate" "nexus" {
  listener_arn    = aws_lb_listener.https.arn
  certificate_arn = data.aws_acm_certificate.nexus.arn
}

# -----------------------------------------
# Jenkins HTTPS Routing
# -----------------------------------------
resource "aws_lb_listener_rule" "jenkins_https" {
  listener_arn = aws_lb_listener.https.arn
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

# -----------------------------------------
# SonarQube HTTPS Routing
# -----------------------------------------
resource "aws_lb_listener_rule" "sonarqube_https" {
  listener_arn = aws_lb_listener.https.arn
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

# -----------------------------------------
# Nexus HTTPS Routing
# -----------------------------------------
resource "aws_lb_listener_rule" "nexus_https" {
  listener_arn = aws_lb_listener.https.arn
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
