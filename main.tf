locals {
  data = {
    user       = var.user
    password   = var.password
    ssh_key    = var.ssh_key
    volume_dev = var.volume_dev
    root_dev   = var.root_dev
    context    = var.context
  }
}

output "cloud_init" {
  value = templatefile("${path.module}/cloud_init/cloudd.cfg", local.data)
}
