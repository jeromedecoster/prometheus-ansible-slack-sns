# https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file
# ⚠ note : generate ansible `inventory.yml` using terraform templating is ok for
# a demo but don't do this for real project. YAML indentation can cause errors.
#
# https://www.redhat.com/sysadmin/ansible-dynamic-inventories
# create dynamic inventory files in ansible
# https://docs.ansible.com/ansible/latest/inventory_guide/intro_dynamic_inventory.html#other-inventory-scripts
# inventory scripts 
# https://docs.ansible.com/ansible/latest/plugins/inventory.html#inventory-plugins
# inventory plugins
resource "local_file" "template_argocd" {
  for_each = fileset("${var.project_dir}/ansible/.tmpl/", "**")
  content  = templatefile("${var.project_dir}/ansible/.tmpl/${each.value}", local.template_vars)
  filename = pathexpand("${var.project_dir}/ansible/${each.value}")
}