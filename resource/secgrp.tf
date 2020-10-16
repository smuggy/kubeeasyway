resource aws_security_group kubernetes_security_group {
  name   = "kube_sg"
  vpc_id = local.vpc_id

  tags = {
    "kubernetes.io/cluster/test-cluster" = "owned"
  }
}

resource aws_security_group_rule icmp {
  security_group_id = aws_security_group.kubernetes_security_group.id
  type              = "ingress"
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = -1
  to_port           = -1
}

resource aws_security_group_rule ssh {
  security_group_id = aws_security_group.kubernetes_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 22
  to_port           = 22
}

resource aws_security_group_rule http {
  security_group_id = aws_security_group.kubernetes_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 80
  to_port           = 80
}

resource aws_security_group_rule https {
  security_group_id = aws_security_group.kubernetes_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 443
  to_port           = 443
}

resource aws_security_group_rule node_ports {
  security_group_id = aws_security_group.kubernetes_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 30000
  to_port           = 32767
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

resource aws_security_group_rule https_alt {
  security_group_id = aws_security_group.kubernetes_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  from_port         = 6443
  to_port           = 6443
}

resource aws_security_group_rule egress {
  security_group_id = aws_security_group.kubernetes_security_group.id
  type              = "egress"
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
}

resource aws_security_group_rule kube_self_all {
  security_group_id = aws_security_group.kubernetes_security_group.id
  type              = "ingress"
  protocol          = "all"
  from_port         = 0
  to_port           = 65535
  self              = true
}
