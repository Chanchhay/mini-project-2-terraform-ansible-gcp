variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  type    = string
  default = "devops-mini"
}

variable "instance_type" {
  type    = string
  default = "t3.large"
}

variable "allowed_ssh_cidrs" {
  description = "Allowed public IP addresses for SSH"
  type        = list(string)

  default = []
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/devops-mini-project.pub"
}

variable "jenkins_domain" {
  description = "Jenkins DuckDNS hostname"
  type        = string
}

variable "sonarqube_domain" {
  description = "SonarQube DuckDNS hostname"
  type        = string
}

variable "nexus_domain" {
  description = "Nexus DuckDNS hostname"
  type        = string
}