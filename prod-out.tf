# The code below shows how to block the internet in this environment. 
# This says to create the prod account, create the SCP and only attach it directly to this OU; 
# and this OU only has the prod account. 

resource "aws_organizations_account" "prod" {
  # A friendly name for the member account
  name  = "my-prod"
  email = "my-prod@email.com"

  # Enables IAM users to access account billing information 
  # if they have the required permissions
  iam_user_access_to_billing = "ALLOW"

  tags = {
    Name  = "my-prod"
    Owner = "Waleed"
    Role  = "prod"
  }

  parent_id = aws_organizations_organizational_unit.prod.id
}

resource "aws_organizations_organizational_unit" "prod" {
  name      = "prod"
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

data "aws_caller_identity" "current" {}

# ------------------------------- #
# PREVENT INTERNET ACCESS TO A VPC 
# ------------------------------- #

data "aws_iam_policy_document" "block_internet" {
  statement {
    sid    = "BlockInternet"
    effect = "Deny"
    actions = [
      "ec2:AttachInternetGateway",
      "ec2:CreateInternetGateway",
      "ec2:CreateEgressOnlyInternetGateway",
      "ec2:CreateVpcPeeringConnection",
      "ec2:AcceptVpcPeeringConnection",
      "globalaccelerator:Create*",
      "globalaccelerator:Update*"
    ]
    resources = ["*"]

  }
}

resource "aws_organizations_policy" "block_internet" {
  name        = "block_internet"
  description = "Block internet access to the production network."
  content     = data.aws_iam_policy_document.block_internet.json
}

resource "aws_organizations_policy_attachment" "block_internet_on_prod" {
  policy_id = aws_organizations_policy.block_internet.id
  target_id = aws_organizations_organizational_unit.prod.id
}

resource "aws_organizations_policy_attachment" "block_internet_on_master" {
  policy_id = aws_organizations_policy.restrict_regions.id
  target_id = data.aws_caller_identity.current.id
}