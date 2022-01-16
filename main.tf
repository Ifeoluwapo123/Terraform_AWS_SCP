
provider "aws" {
  alias  = "replica"
  region = "us-west-1"
}

data "aws_organizations_organization" "this" {}