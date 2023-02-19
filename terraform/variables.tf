variable "project_dir" {
  default = ""
}

variable "project_name" {
  default = ""
}

variable "sns_email" {
  default = ""
}

variable "aws_region" {
  default = ""
}

variable "aws_profile" {
  default = ""
}

variable "ansible_all_ips" {
  default = ["10.30.30.30", "10.30.30.40"]
  type    = list(string)
}

variable "ansible_monitoring_ips" {
  default = ["10.30.30.50"]
  type    = list(string)
}