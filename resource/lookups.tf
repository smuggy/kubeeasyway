locals {
  ami_owner    = "099720109477"    # Canonical Group Limited
  ami_id       = data.aws_ami.ubuntu.id
  key_name     = "ez-kube-key"
  vpc_id       = data.aws_vpc.kube_vpc.id
  vpc_name     = "kube-us-east-2-vpc"
  secgrp_name  = "kube_vpc_default"
  secgrp_id    = data.aws_security_group.vpc_secgrp.id
  az_list      = ["us-east-2a", "us-east-2b", "us-east-2c"]
  subnet_map   = {
    "us-east-2a" = data.aws_subnet.kube_subnet_one.id,
    "us-east-2b" = data.aws_subnet.kube_subnet_two.id,
    "us-east-2c" = data.aws_subnet.kube_subnet_three.id}
  region       = data.aws_region.current.name
}

# 18.04 LTS Bionic amd 64 hvm:ebs-ssd
data aws_ami ubuntu {
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-disco-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [local.ami_owner]  # Canonical Group Limited
}

data aws_region current {}

data aws_security_group vpc_secgrp {
  name = local.secgrp_name
}

data aws_vpc kube_vpc {
  tags = {
    Name = local.vpc_name
  }
}

data aws_subnet kube_subnet_one {
  vpc_id            = local.vpc_id
  availability_zone = element(local.az_list, 0)
}

data aws_subnet kube_subnet_two {
  vpc_id            = local.vpc_id
  availability_zone = element(local.az_list, 1)
}

data aws_subnet kube_subnet_three {
  vpc_id            = local.vpc_id
  availability_zone = element(local.az_list, 2)
}
