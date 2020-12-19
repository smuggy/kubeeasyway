locals {
  account_id = "123991868349"
}

resource aws_iam_user storageclass_user {
  name = "kube_sc_user"
}

resource aws_kms_key sc_volume_key {
  policy = data.aws_iam_policy_document.sc_key_policy.json
}

resource aws_kms_alias sc_key_alias {
  target_key_id = aws_kms_key.sc_volume_key.arn
  name          = "alias/kube-pv-key"
}

data aws_iam_policy_document sc_key_policy {
  statement {
    sid    = "csi_policy"
    effect = "Allow"
    principals {
      identifiers = [aws_iam_user.storageclass_user.arn]
      type        = "AWS"
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "key_management"
    effect = "Allow"
    principals {
      identifiers = [
        "arn:aws:iam::${local.account_id}:root",
        "arn:aws:iam::${local.account_id}:user/tfuser"
      ]
      type = "AWS"
    }
    actions = [
      "kms:Enable*",
      "kms:Disable*",
      "kms:Describe*",
      "kms:Get*",
      "kms:List*",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
      "kms:Create*",
      "kms:Delete*",
      "kms:Update*",
      "kms:Put*",
      "kms:Revoke*"
    ]
    resources = [
      "*"
    ]
  }
}

resource aws_iam_policy instance_policy {
  name   = "sc-user-volume-policy"
  policy = data.aws_iam_policy_document.sc_volume_policy.json
}

data aws_iam_policy_document sc_volume_policy {
  statement {
    sid     = "keyAccessPolicy"
    effect  = "Allow"
    actions = [
      "kms:CreateGrant"
    ]
    resources = [
      aws_kms_key.sc_volume_key.arn
    ]
    condition {
      test     = "StringEquals"
      values   = [aws_iam_user.storageclass_user.name]
      variable = "aws:username"
    }
  }

  statement {
    sid     = "ec2AccessPolicy"
    effect  = "Allow"
    actions = [
      "ec2:DetachVolume",
      "ec2:AttachVolume",
      "ec2:DeleteSnapshot",
      "ec2:DescribeInstances",
      "ec2:DeleteTags",
      "ec2:DescribeTags",
      "ec2:CreateTags",
      "ec2:DescribeSnapshots",
      "ec2:DescribeSecurityGroups",
      "ec2:CreateVolume",
      "ec2:DeleteVolume",
      "ec2:DescribeVolumes",
      "ec2:CreateSnapshot"
    ]
    resources = [
      "*"
    ]
    condition {
      test     = "StringEquals"
      values   = [aws_iam_user.storageclass_user.name]
      variable = "aws:username"
    }
  }
}

resource aws_iam_user_policy_attachment kube_sc_user {
  user       = aws_iam_user.storageclass_user.name
  policy_arn = aws_iam_policy.instance_policy.arn
}

resource aws_iam_access_key sc_access {
  user = aws_iam_user.storageclass_user.name
}

resource local_file master_host_var {
  file_permission = 0644
  filename        = "../infra/host_vars/${element(local.internal_master_names, 0)}"
  content         = <<CONTENT
access_id: ${aws_iam_access_key.sc_access.id}
secret_key: ${aws_iam_access_key.sc_access.secret}
storage_class_key: ${aws_kms_key.sc_volume_key.arn}
CONTENT
}

output sc_volume_key_id {
  value = aws_kms_key.sc_volume_key.arn
}

#===================================
# Test EFS below
#===================================
//resource aws_efs_file_system csi_efs_test {
//  tags = {
//    "name" = "efs-csi-test"
//  }
//}

//resource aws_efs_mount_target csi_efs_mt_a {
//  file_system_id  = aws_efs_file_system.csi_efs_test.id
//  subnet_id       = data.aws_subnet.kube_subnet_one.id
//  security_groups = [aws_security_group.storage_security_group.id, aws_security_group.kubernetes_security_group.id]
//}
//
//resource aws_efs_mount_target csi_efs_mt_b {
//  file_system_id  = aws_efs_file_system.csi_efs_test.id
//  subnet_id       = data.aws_subnet.kube_subnet_two.id
//  security_groups = [aws_security_group.storage_security_group.id, aws_security_group.kubernetes_security_group.id]
//}

// === access point not needed ===
//resource aws_efs_access_point csi_efs_access_point {
//  file_system_id = aws_efs_file_system.csi_efs_test.id
//}

//output efs_arn {
//  value = aws_efs_file_system.csi_efs_test.arn
//}
//
//output efs_name {
//  value = aws_efs_file_system.csi_efs_test.id
//}
//
//resource aws_security_group storage_security_group {
//  name   = "storage_sg"
//  vpc_id = local.vpc_id
//}
//
//resource aws_security_group_rule efs_icmp {
//  security_group_id = aws_security_group.storage_security_group.id
//  type              = "ingress"
//  protocol          = "icmp"
//  cidr_blocks       = ["10.0.0.0/8"]
//  from_port         = -1
//  to_port           = -1
//}
//
//resource aws_security_group_rule efs_rule {
//  security_group_id = aws_security_group.storage_security_group.id
//  type              = "ingress"
//  protocol          = "tcp"
//  cidr_blocks       = ["10.0.0.0/8"]
//  from_port         = 0
//  to_port           = 65535
//}

#kind: StorageClass
#apiVersion: storage.k8s.io/v1
#metadata:
#name: efs-sc
#provisioner: efs.csi.aws.com

//apiVersion: v1
//kind: PersistentVolume
//metadata:
//name: efs-pv
//spec:
//capacity:
//storage: 5Gi
//volumeMode: Filesystem
//accessModes:
//- ReadWriteOnce
//persistentVolumeReclaimPolicy: Retain
//storageClassName: efs-sc
//csi:
//driver: efs.csi.aws.com
//volumeHandle: fs-e8a95a42

//apiVersion: v1
//kind: PersistentVolumeClaim
//metadata:
//name: efs-claim
//spec:
//accessModes:
//- ReadWriteOnce
//storageClassName: efs-sc
//resources:
//requests:
//storage: 5Gi

//apiVersion: v1
//kind: Pod
//metadata:
//name: efs-app
//spec:
//containers:
//- name: app
//image: centos
//command: ["/bin/sh"]
//args: ["-c", "while true; do echo $(date -u) >> /data/out.txt; sleep 5; done"]
//volumeMounts:
//- name: persistent-storage
//mountPath: /data
//volumes:
//- name: persistent-storage
//persistentVolumeClaim:
//claimName: efs-claim
