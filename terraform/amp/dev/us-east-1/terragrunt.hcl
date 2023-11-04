terraform {
  source = "${get_repo_root()}/terraform/modules//amp"
}

include "root" {
  path   = find_in_parent_folders()
  expose = true
}

inputs = {
  aws_region       = "us-east-1"
  environment_name = "dev"
}
