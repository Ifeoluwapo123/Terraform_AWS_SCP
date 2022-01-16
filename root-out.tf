# my root-out.tf contains the master account code and all the service control policies that I want to be applied to all accounts. 
# Notice it’s attached to the root OU which then it’s inherited by all the accounts below the root OU!

# resource "aws_organizations_account" "master" {
#   # A friendly name for the member account
#   name  = "my-master"
#   email = "mymaster@email.com"

#   # Enables IAM users to access account billing information 
#   # if they have the required permissions
#   # iam_user_access_to_billing = "ALLOW"

#   tags = {
#     Name  = "my-master"
#     Owner = "Waleed"
#     Role  = "billing"
#   }

#   parent_id = data.aws_organizations_organization.this.roots[0].id
# }

# ---------------------------------------- # 
# Service Control Policies for all accounts
# ---------------------------------------- #

# ---------------------------- #
# REGION RESTRICTION 
# ---------------------------- #

data "aws_iam_policy_document" "restrict_regions" {
  statement {
    sid       = "RegionRestriction"
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"

      values = [
        "us-east-1"
      ]
    }
  }
}

resource "aws_organizations_policy" "restrict_regions" {
  name        = "restrict_regions"
  description = "Deny all regions except US East 1."
  content     = data.aws_iam_policy_document.restrict_regions.json
}

resource "aws_organizations_policy_attachment" "restrict_regions_on_root" {
  policy_id = aws_organizations_policy.restrict_regions.id
  target_id = data.aws_organizations_organization.this.roots[0].id
}

# ---------------------------- #
# EC2 INSTANCE TYPE RESTRICTION 
# ---------------------------- #

data "aws_iam_policy_document" "restrict_ec2_types" {
  statement {
    sid       = "RestrictEc2Types"
    effect    = "Deny"
    actions   = ["ec2:RunInstances"]
    resources = ["arn:aws:ec2:*:*:instance/*"]

    condition {
      test     = "StringNotEquals"
      variable = "ec2:InstanceType"

      values = [
        "t3*",
        "t4g*",
        "a1.medium",
        "a1.large"
      ]
    }
  }
}

resource "aws_organizations_policy" "restrict_ec2_types" {
  name        = "restrict_ec2_types"
  description = "Allow certain EC2 instance types only."
  content     = data.aws_iam_policy_document.restrict_ec2_types.json
}

resource "aws_organizations_policy_attachment" "restrict_ec2_types_on_root" {
  policy_id = aws_organizations_policy.restrict_ec2_types.id
  target_id = data.aws_organizations_organization.this.roots[0].id
}

# ---------------------------- #
# REQUIRE EC2 TAGS 
# ---------------------------- #

data "aws_iam_policy_document" "require_ec2_tags" {
  statement {
    sid    = "RequireTag"
    effect = "Deny"
    actions = [
      "ec2:RunInstances",
      "ec2:CreateVolume" //ebs(elastic block storage) volume
    ]
    resources = [
      "arn:aws:ec2:*:*:instance/*",
      "arn:aws:ec2:*:*:volume/*"
    ]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/Name"

      values = ["true"]
    }
  }
}

resource "aws_organizations_policy" "require_ec2_tags" {
  name        = "require_ec2_tags"
  description = "Name tag is required for EC2 instances and volumes."
  content     = data.aws_iam_policy_document.require_ec2_tags.json
}

resource "aws_organizations_policy_attachment" "require_ec2_tags_on_root" {
  policy_id = aws_organizations_policy.require_ec2_tags.id
  target_id = data.aws_organizations_organization.this.roots[0].id
}