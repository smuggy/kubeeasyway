data aws_route53_zone internal {
  name         = "internal.podspace.net"
  private_zone = true
}

#data aws_route53_zone internal {
#  name         = "podspace.local"
#  private_zone = true
#}

data aws_route53_zone reverse {
  name         = "20.10.in-addr.arpa"
  private_zone = true
}

resource aws_route53_record master_internal {
  zone_id = data.aws_route53_zone.internal.zone_id
  count   = local.master_count
  name    = local.internal_master_names[count.index]
  type    = "A"
  ttl     = "300"
  records = [lookup(aws_instance.master[count.index], "private_ip")]
}

resource aws_route53_record master_reverse {
  zone_id = data.aws_route53_zone.reverse.zone_id
  count   = local.master_count
  name    = join(".", reverse(regex("[[:digit:]]*.[[:digit:]]*.([[:digit:]]*).([[:digit:]]*)",
                      lookup(aws_instance.master[count.index], "private_ip"))))
  type    = "PTR"
  ttl     = "300"
  records = [local.internal_master_names[count.index]]
}

resource aws_route53_record worker_reverse {
  zone_id = data.aws_route53_zone.reverse.zone_id
  count   = local.worker_count
  name    = join(".", reverse(regex("[[:digit:]]*.[[:digit:]]*.([[:digit:]]*).([[:digit:]]*)",
                      lookup(aws_instance.workers[count.index], "private_ip"))))
  type    = "PTR"
  ttl     = "300"
  records = [local.internal_worker_names[count.index]]
}

resource aws_route53_record kubernetes_name {
  zone_id = data.aws_route53_zone.internal.zone_id
  count   = 1
  name    = "kubernetes.internal.podspace.net"
  type    = "A"
  ttl     = "300"
  records = aws_instance.master.*.private_ip
}

resource aws_route53_record worker_internal {
  zone_id = data.aws_route53_zone.internal.zone_id
  count   = local.worker_count
  name    = local.internal_worker_names[count.index]
  type    = "A"
  ttl     = "300"
  records = [lookup(aws_instance.workers[count.index], "private_ip")]
}
