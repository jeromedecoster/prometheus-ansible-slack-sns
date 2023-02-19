locals {
  ssh_public_key  = pathexpand("~/.ssh/${var.project_name}.pub")
  ssh_private_key = pathexpand("~/.ssh/${var.project_name}")

  template_vars = {
    all_ips        = var.ansible_all_ips
    monitoring_ips = var.ansible_monitoring_ips
  }
}