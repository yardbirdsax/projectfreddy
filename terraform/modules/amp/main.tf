terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
}

module "tags" {
  source = "../tags"

  environment_name = var.environment_name
}

resource "aws_prometheus_workspace" "this" {
  alias = join("-", ["projectfreddy", var.environment_name])
  tags  = module.tags.tags
}
