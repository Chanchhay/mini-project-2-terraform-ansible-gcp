provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "devops-mini-project"
      Environment = "lab"
      ManagedBy   = "Terraform"
    }
  }
}