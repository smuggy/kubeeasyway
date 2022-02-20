resource tls_private_key ssh_key {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource local_file private_key_file {
  sensitive_content    = tls_private_key.ssh_key.private_key_pem
  filename             = "../secrets/ez-kube-private-key.pem"
  file_permission      = 0400
  directory_permission = 0755
}

resource local_file public_key_file {
  content              = tls_private_key.ssh_key.public_key_pem
  filename             = "../secrets/ez-kube-public-key.pem"
  file_permission      = 0644
  directory_permission = 0755
}
