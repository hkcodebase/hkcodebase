data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# S3 (private) bucket for static site assets (least privilege: CloudFront-only)
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "website_storage" {
  bucket = "portfolio-website-bucket-${data.aws_caller_identity.current.account_id}"

  tags = {
    project    = var.project_name
    managed_by = "terraform"
  }
}

# Best practice: block ALL public access
resource "aws_s3_bucket_public_access_block" "website_storage" {
  bucket = aws_s3_bucket.website_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Best practice: enforce bucket owner ownership (disables ACLs)
resource "aws_s3_bucket_ownership_controls" "website_storage" {
  bucket = aws_s3_bucket.website_storage.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Best practice: encryption at rest (SSE-S3). Use KMS if you have compliance needs.
resource "aws_s3_bucket_server_side_encryption_configuration" "website_storage" {
  bucket = aws_s3_bucket.website_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Best practice: versioning helps recover from accidental overwrites/deletes
resource "aws_s3_bucket_versioning" "website_storage" {
  bucket = aws_s3_bucket.website_storage.id

  versioning_configuration {
    status = "Suspended"
  }
}

# -----------------------------------------------------------------------------
# CloudFront (uses S3 REST origin + OAC) - NOT S3 website endpoint
# -----------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_control" "website_oac" {
  name                              = "${var.project_name}-oac"
  description                       = "OAC for private S3 origin access"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "website_storage" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  origin {
    domain_name              = aws_s3_bucket.website_storage.bucket_regional_domain_name
    origin_id                = "s3_origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.website_oac.id

    s3_origin_config {
      origin_access_identity = ""
    }
  }

  default_cache_behavior {
    target_origin_id       = "s3_origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    project    = var.project_name
    managed_by = "terraform"
  }
}

# Allow ONLY CloudFront (this distribution) to read objects from the bucket
resource "aws_s3_bucket_policy" "website_storage" {
  bucket = aws_s3_bucket.website_storage.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontReadOnlyViaOAC"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.website_storage.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.website_storage.arn
          }
        }
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.website_storage,
    aws_cloudfront_distribution.website_storage
  ]
}

# -----------------------------------------------------------------------------
# GitHub Actions OIDC (unchanged behavior; keep least privilege in IAM below)
# -----------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["2b18947a6a9fc7764fd8b5fb18a863b0c6dac24f"]
}

resource "aws_iam_role" "github_actions" {

  name = "${var.project_name}_githubactions_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"

        "Condition": {
          "StringEquals": {
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
          },
          "StringLike": {
            "token.actions.githubusercontent.com:sub": "repo:${var.github_username}/${var.repo_name}:environment:prod"
          }
        }
      }
    ]
  })

  tags = {
    Project = var.project_name
  }
}

# Least privilege:
# - ListBucket on bucket ARN only
# - Object actions on object ARNs only
# - No PutObjectAcl (ACLs are disabled via BucketOwnerEnforced)
resource "aws_iam_role_policy" "github_actions_policy" {
  name = "${var.project_name}_githubactions_role_policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListBucket"
        Effect = "Allow"
        Action = ["s3:ListBucket"]
        Resource = [
          aws_s3_bucket.website_storage.arn
        ]
      },
      {
        Sid    = "ManageSiteObjects"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.website_storage.arn}/*"
        ]
      },
      {
        Sid      = "InvalidateCloudFront"
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation"]
        Resource = aws_cloudfront_distribution.website_storage.arn
      }
    ]
  })
}
