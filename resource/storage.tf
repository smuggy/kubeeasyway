#resource aws_s3_bucket kubernetes_state {
#  bucket = "kubernetes.podspace.net"
#  acl    = "private"
#}

resource aws_iam_access_key ku_access {
  user = "kubesa"
}

#resource aws_ebs_volume worker_vol {
#  count             = local.worker_count
#  availability_zone = element(local.az_list, count.index)
#  size              = 3

#  tags = {
#    az   = element(local.az_list,count.index)
#    type = "PV"
#  }
#}

#resource aws_volume_attachment worker_vol_att {
#  count        = local.worker_count
#  volume_id    = element(aws_ebs_volume.worker_vol.*.id, count.index)
#  instance_id  = element(aws_instance.workers.*.id, count.index)
#  device_name  = "/dev/sdf"
#  force_detach = true
#}

output access_key {
  value = aws_iam_access_key.ku_access.id
}

output access_secret {
  value = aws_iam_access_key.ku_access.secret
}