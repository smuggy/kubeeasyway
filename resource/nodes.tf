locals {
  worker_count = 2
  master_count = 1
  master_ip    = data.aws_eip.kubernetes.public_ip
  master_hosts = formatlist("ezkm-%d.internal.podspace.net ansible_host=%s private_dns=%s provider_id=aws:///%s/%s",
                            range(local.master_count), local.master_ip,
                            aws_instance.master.*.private_dns,
                            aws_instance.master.*.availability_zone,
                            aws_instance.master.*.id)
//                            aws_instance.master.*.public_ip)

  internal_master_names = formatlist("ezkm-%d.internal.podspace.net", range(local.master_count))
  worker_hosts          = formatlist("ezkw-%d.internal.podspace.net ansible_host=%s private_dns=%s provider_id=aws:///%s/%s",
                                     range(local.worker_count),
                                     aws_instance.workers.*.public_ip,
                                     aws_instance.workers.*.private_dns,
                                     aws_instance.workers.*.availability_zone,
                                     aws_instance.workers.*.id)
  internal_worker_names = formatlist("ezkw-%d.internal.podspace.net", range(local.worker_count))
  worker_ids            = formatlist("%s: %s", aws_instance.workers.*.id, local.internal_worker_names)
  master_ids            = formatlist("%s: %s", aws_instance.master.*.id, local.internal_master_names)
}

resource aws_instance master {
  ami               = local.ami_id
  instance_type     = "t3a.small"
  key_name          = local.key_name
  availability_zone = element(local.az_list, count.index)
  subnet_id         = lookup(local.subnet_map, element(local.az_list, count.index))
  count             = local.master_count

  iam_instance_profile   = data.aws_iam_instance_profile.kube_node_profile.name
  vpc_security_group_ids = [aws_security_group.kubernetes_security_group.id]

  root_block_device {
    volume_size = 8
  }

  tags = {
    Name     = format("ezkm-%d", count.index)
    KubeNode = "true"
    "kubernetes.io/cluster/testcluster" = "owned" //owned or shared
  }
}

resource aws_instance workers {
  ami               = local.ami_id
  instance_type     = "t3a.medium"
  availability_zone = element(local.az_list, count.index)
  count             = local.worker_count
  key_name          = local.key_name
  subnet_id         = lookup(local.subnet_map, element(local.az_list, count.index))

  iam_instance_profile   = data.aws_iam_instance_profile.kube_node_profile.name
  vpc_security_group_ids = [aws_security_group.kubernetes_security_group.id]

  root_block_device {
    volume_size = 8
  }
  tags = {
    Name       = format("ezkw-%d", count.index)
    NodeExport = "true"
    KubeNode   = "true"
    "kubernetes.io/cluster/testcluster" = "owned" //owned or shared
  }
}

data template_file all_hosts {
  template   = file("${path.module}/templates/hosts.tpl")
  depends_on = [aws_instance.master, aws_instance.workers]
  vars = {
    master_host_group = join("\n", local.master_hosts)
    worker_host_group = join("\n", local.worker_hosts)
  }
}

resource local_file host_file {
  content         = data.template_file.all_hosts.rendered
  file_permission = 0644
  filename        = "../infra/all_hosts"
}

resource local_file local_host_vars {
  filename        = "../infra/host_vars/localhost"
  content         = "instance_ids:\n  - ${join("\n  - ", local.worker_ids)}\n  - ${join("\n  - ", local.master_ids)}"
  file_permission = 0444
}

#resource local_file host_vars {
#  count           = local.worker_count
#  filename        = "../infra/host_vars/${element(local.internal_worker_names, count.index)}"
#  content         = "worker_az: ${element(aws_instance.workers.*.availability_zone, count.index)}\n\n"
#  file_permission = 0444
#}

data aws_eip kubernetes {
  tags = {
    Name = "kubernetes"
  }
}

resource aws_eip_association kubernetes_master {
  allocation_id = data.aws_eip.kubernetes.id
  instance_id   = aws_instance.master.*.id[0]
}

output master_public_ip {
  value = aws_eip_association.kubernetes_master.public_ip
//  value = aws_instance.master.*.public_ip
}
