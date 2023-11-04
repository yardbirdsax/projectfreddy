remote_state {
  backend = "s3"
  config = {
    bucket                = "jef-remote-state"
    disable_bucket_update = true
    encrypt               = true
    key                   = "projectfreddy/${path_relative_to_include()}/terraform.tfstate"
    profile               = "Joshua-E-Feierman.AdministratorAccess"
    region                = "us-east-1"
  }
  generate = {
    path      = "_backend.tf"
    if_exists = "overwrite"
  }
}

generate "providers" {
  path      = "_providers.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
  variable "aws_region" {
    type = string
  }

  provider "aws" {
    profile = "projectfreddy.AdministratorAccess"
    region  = var.aws_region
  }
  EOF
}
