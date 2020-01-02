#resource aws_iam_instance_profile kube_node {
#  name = "kube_instance"
#  role = aws_iam_role.instance_role.name
#}

#resource aws_iam_role instance_role {
#  name = "kube_instance_role"

#  assume_role_policy = <<EOF
#{
#  "Version": "2012-10-17",
#  "Statement": [
#    {
#      "Action": "sts:AssumeRole",
#      "Principal": {
#        "Service": "ec2.amazonaws.com"
#      },
#      "Effect": "Allow",
#      "Sid": ""
#    }
#  ]
#}
#EOF
#}

#resource aws_iam_policy instance_policy {
#  name = "kube-volume-policy"
#  policy = <<POLICY
#{
#  "Version": "2012-10-17",
#  "Statement": [
#    {
#      "Action": [
#        "ec2:DescribeInstances",
#        "ec2:AttachVolume",
#        "ec2:DetachVolume",
#        "ec2:DescribeVolumes",
#        "ec2:CreateVolume",
#        "ec2:DeleteVolume",
#        "ec2:CreateTags",
#        "ec2:DescribeSecurityGroups",
#        "ec2:CreateSnapshot",
#        "ec2:DeleteSnapshot",
#        "ec2:DescribeSnapshots",
#        "ec2:CreateTags",
#        "ec2:DeleteTags",
#        "ec2:DescribeTags"
#      ],
#      "Effect": "Allow",
#      "Resource": [
#        "*"
#      ]
#    }
#  ]
#}
#POLICY
#}

#resource aws_iam_user_policy_attachment kube_user {
#  user = "kubesa"
#  policy_arn = aws_iam_policy.instance_policy.arn
#}

#resource aws_iam_role_policy_attachment volume_policy {
#  role = aws_iam_role.instance_role.name
#  policy_arn = aws_iam_policy.instance_policy.arn
#}
