
variable "aws_region" {
  description = "AWS region to use"
  type        = string
  default     = ""
}

variable "project_name" {
  description = "current project name can bse used for tagging"
  type = string
  default = ""
}

variable "github_username" {
  type = string
  default = ""
}

variable "repo_name" {
  type = string
  default = ""
}

# -----------------------------------------------------------------------------
# CloudFront custom domain + ACM cert (must be in us-east-1 for CloudFront)
# -----------------------------------------------------------------------------
variable "cloudfront_aliases" {
  description = "Alternate domain names (CNAMEs) for the CloudFront distribution"
  type        = list(string)
  default     = [""]
}

variable "cloudfront_acm_certificate_arn" {
  description = "ACM certificate ARN in us-east-1 to attach to CloudFront"
  type        = string
  default     = ""
}