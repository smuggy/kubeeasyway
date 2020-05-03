//resource aws_route53_zone internal {
//  name = "internal.podspace.net"
//  vpc {
//    vpc_id = local.vpc_id
//  }
//}
//
//resource aws_route53_zone reverse {
//  name = "20.10.in-addr.arpa"
//  vpc {
//    vpc_id = local.vpc_id
//  }
//}
data aws_route53_zone internal {
  name         = "internal.podspace.net"
  private_zone = true
}

data aws_route53_zone reverse {
  name         = "20.10.in-addr.arpa"
  private_zone = true
}

//resource aws_route53_record ns {
//  allow_overwrite = true
//  zone_id         = data.aws_route53_zone.internal.zone_id
//  name            = "internal.podspace.net"
//  type            = "NS"
//  ttl             = "30"
//  records         = [data.aws_route53_zone.internal.name_servers]
//
//  records = [
//    data.aws_route53_zone.internal.name_servers.0,
//    data.aws_route53_zone.internal.name_servers.1,
//    data.aws_route53_zone.internal.name_servers.2,
//    data.aws_route53_zone.internal.name_servers.3,
//  ]
//}

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

#resource aws_route53_record master_internal_reverse {
#  zone_id = aws_route53_zone.internal.zone_id
#  count   = 1
#  name    = lookup(aws_instance.master[count.index], "private_ip")
#  records = [local.internal_master_names[count.index]]
#  type    = "PTR"
#  ttl     = "300"
#}

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
