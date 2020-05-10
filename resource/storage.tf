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
