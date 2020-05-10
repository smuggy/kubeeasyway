provider local {
  version = "~> 1.4"
}

provider tls {
  version = "~> 2.1"
}

provider aws {
  region  = "us-east-2"
  version = "~> 2.60"
}

terraform {
  required_version = ">= 0.12"
}
