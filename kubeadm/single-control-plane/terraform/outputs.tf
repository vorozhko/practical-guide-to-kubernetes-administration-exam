output "master_ip" {
  description = "Master ip."
  value       = aws_instance.kubernetes_master.public_ip
}
# output "worker_ip" {
#   description = "Worker ip."
#   value       = aws_instance.kubernetes_worker.public_ip
# }
output "region" {
  description = "AWS region."
  value       = var.region
}