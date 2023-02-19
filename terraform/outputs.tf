output "project_dir" {
  value = var.project_dir
}

output "project_name" {
  value = var.project_name
}

output "aws_region" {
  value = var.aws_region
}

output "aws_profile" {
  value = var.aws_profile
}

output "sns_email" {
  value = var.sns_email
}

output "ansible_all_ips" {
  value = var.ansible_all_ips
}

output "ansible_monitoring_ips" {
  value = var.ansible_monitoring_ips
}

output "ssh_public_key" {
  value = local.ssh_public_key
}
