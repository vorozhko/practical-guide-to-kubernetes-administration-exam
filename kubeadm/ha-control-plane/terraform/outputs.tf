output "region" {
  description = "AWS region."
  value       = var.region
}

output "dns_name" {
  description = "LB DNS."
  value       = aws_lb.master.dns_name
}