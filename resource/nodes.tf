locals {
  worker_count = 2
  master_hosts = formatlist("ezkm-%d.internal.podspace.net ansible_host=%s", range(1), aws_instance.master.*.public_ip)
  internal_master_names = formatlist("ezkm-%d.internal.podspace.net", range(1))

  worker_hosts = formatlist("ezkw-%d.internal.podspace.net ansible_host=%s", range(local.worker_count), aws_instance.workers.*.public_ip)
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
    Name = format("ezkm-%d", count.index)
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
  }
}

resource aws_route53_zone internal {
  name = "internal.podspace.net"
  vpc {
    vpc_id = local.vpc_id
  }
}

resource aws_route53_zone reverse {
  name = "20.10.in-addr.arpa"
  vpc {
    vpc_id = local.vpc_id
  }
}

resource "aws_route53_record" "ns" {
  allow_overwrite = true
  zone_id         = aws_route53_zone.internal.zone_id
  name            = "internal.podspace.net"
  type            = "NS"
  ttl             = "30"

  records = [
    aws_route53_zone.internal.name_servers.0,
    aws_route53_zone.internal.name_servers.1,
    aws_route53_zone.internal.name_servers.2,
    aws_route53_zone.internal.name_servers.3,
  ]
}

resource aws_route53_record master_internal {
  zone_id = aws_route53_zone.internal.zone_id
  count   = 1
  name    = local.internal_master_names[count.index]
  type    = "A"
  ttl     = "300"
  records = [lookup(aws_instance.master[count.index], "private_ip")]
}

resource aws_route53_record master_reverse {
  zone_id = aws_route53_zone.reverse.zone_id
  count   = 1
  name    = join(".", reverse(regex("[[:digit:]]*.[[:digit:]]*.([[:digit:]]*).([[:digit:]]*)", lookup(aws_instance.master[count.index], "private_ip"))))
  type    = "PTR"
  ttl     = "300"
  records = [local.internal_master_names[count.index]]
}

resource aws_route53_record worker_reverse {
  zone_id = aws_route53_zone.reverse.zone_id
  count   = local.worker_count
  name    = join(".", reverse(regex("[[:digit:]]*.[[:digit:]]*.([[:digit:]]*).([[:digit:]]*)", lookup(aws_instance.workers[count.index], "private_ip"))))
  type    = "PTR"
  ttl     = "300"
  records = [local.internal_worker_names[count.index]]
}

#resource aws_route53_record master_internal_reverse {
#  zone_id = aws_route53_zone.internal.zone_id
#  count   = 1
#  name    = lookup(aws_instance.master[count.index], "private_ip")
#  records = [local.internal_master_names[count.index]]
#  type    = "PTR"
#  ttl     = "300"
#}

resource aws_route53_record kubernetes_name {
  zone_id = aws_route53_zone.internal.zone_id
  count   = 1
  name    = "kubernetes.internal.podspace.net"
  type    = "A"
  ttl     = "300"
  records = aws_instance.master.*.private_ip
}

resource aws_route53_record worker_internal {
  zone_id = aws_route53_zone.internal.zone_id
  count   = local.worker_count
  name    = local.internal_worker_names[count.index]
  type    = "A"
  ttl     = "300"
  records = [lookup(aws_instance.workers[count.index], "private_ip")]
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

resource local_file host_vars {
  count           = local.worker_count
  filename        = "../infra/host_vars/${element(local.internal_worker_names, count.index)}"
  content         = "worker_az: ${element(aws_instance.workers.*.availability_zone, count.index)}\n\n"
  file_permission = 0444
}

output master_public_ip {
  value = aws_instance.master.*.public_ip
}
