resource aws_security_group kubernetes_security_group {
  name   = "kube_sg"
  vpc_id = local.vpc_id
}

resource aws_security_group_rule kube_http {
  security_group_id = aws_security_group.kubernetes_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 80
  to_port           = 80
}

resource aws_security_group_rule kube_https {
  security_group_id = aws_security_group.kubernetes_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 443
  to_port           = 443
}

resource aws_security_group_rule node_exporter {
  security_group_id = aws_security_group.kubernetes_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  from_port         = 9100
  to_port           = 9100
}

resource aws_security_group_rule cadvisor {
  security_group_id = aws_security_group.kubernetes_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  from_port         = 8080
  to_port           = 8080
}

resource aws_security_group_rule kube_self_all {
  security_group_id = aws_security_group.kubernetes_security_group.id
  type              = "ingress"
  protocol          = "all"
  from_port         = 0
  to_port           = 65000
  self              = true
}
