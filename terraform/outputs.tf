output "vpc_id" {
  value = aws_vpc.main.id
}

output "security_group_id" {
  value = aws_security_group.servers.id
}

output "instance_ids" {
  value = {
    for name, vm in aws_instance.servers :
    name => vm.id
  }
}

output "public_ips" {
  value = {
    for name, vm in aws_instance.servers :
    name => vm.public_ip
  }
}

output "private_ips" {
  value = {
    for name, vm in aws_instance.servers :
    name => vm.private_ip
  }
}
output "alb_dns_name" {
  description = "Public DNS name of Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "jenkins_target_group_arn" {
  value = aws_lb_target_group.jenkins.arn
}

output "sonarqube_target_group_arn" {
  value = aws_lb_target_group.sonarqube.arn
}

output "nexus_target_group_arn" {
  value = aws_lb_target_group.nexus.arn
}

output "https_listener_arn" {
  description = "ALB HTTPS Listener ARN"
  value       = aws_lb_listener.https.arn
}