/* EC2 IAM Role:Allow EC2 to be managed by SSM Session Manager */

# EC2 IAM Policy Document
data "aws_iam_policy_document" "policy_document" {
  #Systems Manager Limited: List, Read, Write 
  statement {
    sid    = "SystemsManagerLRW"
    effect = "Allow"
    actions = [
      "ssm:DescribeAssociation",
      "ssm:GetDeployablePatchSnapshotForInstance",
      "ssm:GetDocument",
      "ssm:DescribeDocument",
      "ssm:GetManifest",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations",
      "ssm:PutInventory",
      "ssm:PutComplianceItems",
      "ssm:PutConfigurePackageResult",
      "ssm:UpdateAssociationStatus",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:UpdateInstanceInformation"
    ]
    resources = ["*"]
  }

  #SSM Messages Full access
  statement {
    sid    = "SSMMessagesFull"
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }

  #EC2 Messages Full access
  statement {
    sid    = "EC2MessagesFull"
    effect = "Allow"
    actions = [
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "EC2Tagging"
    effect = "Allow"
    actions = [
      "ec2:Get*",
      "ec2:CreateTags",
      "ec2:DescibeTags"
    ]
    resources = ["*"]
  }
}

# EC2 IAM Role Policy Document
data "aws_iam_policy_document" "ec2_role_source" {
  statement {
    sid    = "EC2AssumeRole"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# EC2 IAM Policy
resource "aws_iam_policy" "policy" {
  name        = "${var.name_prefix}-EC2-Policy"
  path        = "/"
  description = "${var.name_prefix}-EC2-Policy"
  policy      = data.aws_iam_policy_document.policy_document.json
  tags        = { Name = "${var.name_prefix}-EC2-Policy" }
}

# EC2 IAM Role
resource "aws_iam_role" "role" {
  name               = "${var.name_prefix}-EC2-Role"
  assume_role_policy = data.aws_iam_policy_document.ec2_role_source.json
  tags               = { Name = "${var.name_prefix}-EC2-Role" }
}

# Attach EC2 Role and EC2 Policy
resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}