terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
}

resource "aws_iam_user" "this" {
  name = join("-", "projectfreddy", "remote-write", var.cluster_name, )
}
