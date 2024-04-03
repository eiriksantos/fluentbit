provider "aws" {
  region = "us-east-1" # Change the region if needed
}

variable "aws_account_id" {
  description = "AWS account ID"
}

variable "cluster_id" {
  description = "EKS cluster ID"
}

variable "bucket_name" {
  description = "my bucket for fluentbit"
}

resource "aws_iam_role" "s3_full_access_role" {
  name = "s3_full_access_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/${var.cluster_id}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "oidc.eks.us-east-1.amazonaws.com/id/${var.cluster_id}:sub" = "system:serviceaccount:logging:fluent-bit"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "s3_full_access_policy" {
  name        = "s3_full_access_policy"
  description = "Policy allowing full access to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "s3:*"
      Resource = "*"
    }]
  })
}

resource "aws_iam_policy_attachment" "s3_full_access_attachment" {
  name       = "s3_full_access_attachment"
  roles      = [aws_iam_role.s3_full_access_role.name]
  policy_arn = aws_iam_policy.s3_full_access_policy.arn
}

resource "aws_s3_bucket" "esantos_s3_bucket" {
  bucket = var.bucket_name
}
