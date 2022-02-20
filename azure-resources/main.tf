locals {
  worker_count = 2
  master_count = 1
  master_ips   = module.master.*.public_ip
  master_hosts = formatlist("ezkm-%d.podspace.cloud ansible_host=%s private_dns=%s",
                             range(local.master_count), local.master_ips,
                             module.master.*.name)
  internal_master_names = formatlist("ezkm-%d", range(local.master_count))
  worker_hosts          = formatlist("ezkw-%d.podspace.cloud ansible_host=%s private_dns=%s",
                                     range(local.worker_count),
                                     module.workers.*.public_ip,
                                     module.workers.*.name)
  internal_worker_names = formatlist("ezkw-%d", range(local.worker_count))
}


module rg {
  source = "git::https://github.com/smuggy/terraform-base//azure/management/resource_group?ref=main"
  name     = "kubernetes"
  group    = "sandbox"
  location = "Central US"
}

module master {
  source = "git::https://github.com/smuggy/terraform-base//azure/compute/linux_vm?ref=main"

  count = local.master_count
  app            = "k8s"
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
  rg_location    = module.rg.rg_location
  rg_name        = module.rg.rg_name
  dns_rg_name    = "sandbox-network-rg"
  subnet         = data.azurerm_subnet.subnet_1.id
  zone           = "1"
  server_number  = count.index
  ami_id         = data.azurerm_shared_image_version.ubuntu.id
  instance_size  = "Standard_B2s"
  server_type    = "ctl"
}

module workers {
  source = "git::https://github.com/smuggy/terraform-base//azure/compute/linux_vm?ref=main"

  count = local.worker_count
  app            = "k8s"
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
  rg_location    = module.rg.rg_location
  rg_name        = module.rg.rg_name
  dns_rg_name    = "sandbox-network-rg"
  subnet         = data.azurerm_subnet.subnet_1.id
  zone           = "1"
  server_number  = count.index
  ami_id         = data.azurerm_shared_image_version.ubuntu.id
  instance_size  = "Standard_B2s"
  server_type    = "wrk"
}

output master_public_ips {
  value = module.master.*.public_ip
}

resource local_file host_file {
  content         = templatefile("${path.module}/templates/hosts.tpl",
                                 {"master_host_group": join("\n", local.master_hosts),
                                  "worker_host_group": join("\n", local.worker_hosts)})
  file_permission = 0644
  filename        = "../infra/all_hosts"
}

resource azurerm_dns_a_record master_name {
  zone_name           = "podspace.net"
  resource_group_name = "sandbox-network-rg"
  name                = "kubernetes"
  ttl                 = 300
  records             = module.master.*.public_ip
}

resource azurerm_private_dns_a_record master_internal {
  count = local.master_count
  resource_group_name = "sandbox-network-rg"
  ttl                 = 300
  zone_name           = "podspace.cloud"
  name                = local.internal_master_names[count.index]
  records             = [module.master.*.private_ip[count.index]]
}

resource azurerm_private_dns_a_record worker_internal {
  count = local.worker_count
  resource_group_name = "sandbox-network-rg"
  ttl                 = 300
  zone_name           = "podspace.cloud"
  name                = local.internal_worker_names[count.index]
  records             = [module.workers.*.private_ip[count.index]]
}
