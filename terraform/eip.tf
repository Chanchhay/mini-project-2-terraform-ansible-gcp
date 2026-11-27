resource "aws_eip" "servers" {
  for_each = aws_instance.servers

  domain   = "vpc"
  instance = each.value.id

  tags = {
    Name = "${var.project_name}-${each.key}-eip"
    Role = each.key
  }

  depends_on = [aws_internet_gateway.main]
}
