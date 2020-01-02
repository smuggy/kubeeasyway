resource tls_private_key ssh_key {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource local_file private_key_file {
  sensitive_content  = tls_private_key.ssh_key.private_key_pem
  filename           = "../secrets/ez-kube-private-key.pem"
  file_permission    = 0400

  directory_permission = 0755
}

resource local_file public_key_file {
  content         = tls_private_key.ssh_key.public_key_pem
  filename        = "../secrets/ez-kube-public-key.pem"
  file_permission = 0644

  directory_permission = 0755
}

resource aws_key_pair ez_kube_pair {
  key_name   = local.key_name
  public_key = tls_private_key.ssh_key.public_key_openssh
}

output key_pair_name {
  value = aws_key_pair.ez_kube_pair.key_name
}

data template_file access_creds {
  template   = file("${path.module}/templates/credentials.tpl")
  depends_on = [aws_iam_access_key.ku_access]

  vars = {
    access_key = aws_iam_access_key.ku_access.id
    secret_key = aws_iam_access_key.ku_access.secret
  }
}

resource local_file cred_file {
  file_permission   = 0644
  filename          = "../secrets/aws.credentials"
  sensitive_content = data.template_file.access_creds.rendered
}

resource local_file master_host_var {
  file_permission   = 0644
  filename          = "../infra/host_vars/${element(local.internal_master_names, 0)}"
  content           = "access_id: ${aws_iam_access_key.ku_access.id}\nsecret_key: ${aws_iam_access_key.ku_access.secret}\n"
}
