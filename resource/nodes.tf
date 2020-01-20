locals {
  worker_count = 2
  master_hosts = formatlist("ezkm-%d.internal.podspace.net ansible_host=%s", range(1), aws_instance.master.*.public_ip)
  internal_master_names = formatlist("ezkm-%d.internal.podspace.net", range(1))

  worker_hosts = formatlist("ezkw-%d.internal.podspace.net ansible_host=%s",
                            range(local.worker_count),
                            aws_instance.workers.*.public_ip)
  internal_worker_names = formatlist("ezkw-%d.internal.podspace.net", range(local.worker_count))
}

resource aws_instance master {
  ami               = local.ami_id
  instance_type     = "t3a.small"
  key_name          = local.key_name
  availability_zone = element(local.az_list, count.index)
  subnet_id         = lookup(local.subnet_map, element(local.az_list, count.index))
  count             = 1
#  iam_instance_profile = aws_iam_instance_profile.kube_node.id

  vpc_security_group_ids = [local.secgrp_id, aws_security_group.kubernetes_security_group.id]

  root_block_device {
    volume_size = 8
  }

  tags = {
    Name     = format("ezkm-%d", count.index)
    KubeNode = "true"
  }
}

resource aws_instance workers {
  ami               = local.ami_id
  instance_type     = "t3a.small"
  availability_zone = element(local.az_list, count.index)
  count             = local.worker_count
  key_name          = local.key_name
  subnet_id         = lookup(local.subnet_map, element(local.az_list, count.index))
#  iam_instance_profile = aws_iam_instance_profile.kube_node.id

  vpc_security_group_ids = [local.secgrp_id, aws_security_group.kubernetes_security_group.id]

  root_block_device {
    volume_size = 8
  }
  tags = {
    Name       = format("ezkw-%d", count.index)
    NodeExport = "true"
    KubeNode   = "true"
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

#resource local_file host_vars {
#  count           = local.worker_count
#  filename        = "../infra/host_vars/${element(local.internal_worker_names, count.index)}"
#  content         = "worker_az: ${element(aws_instance.workers.*.availability_zone, count.index)}\n\n"
#  file_permission = 0444
#}

output master_public_ip {
  value = aws_instance.master.*.public_ip
}
