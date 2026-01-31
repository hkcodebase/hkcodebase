
output "website_s3_bucket_name" {
  description = "Name of the S3 bucket that stores the website assets"
  value       = aws_s3_bucket.website_storage.bucket
}

output "website_cloudfront_domain_name" {
  description = "CloudFront distribution domain name (use https://<domain>)"
  value       = aws_cloudfront_distribution.website_storage.domain_name
}

output "website_cloudfront_url" {
  description = "CloudFront URL for the website"
  value       = "https://${aws_cloudfront_distribution.website_storage.domain_name}"
}

output "website_cloudfront_id" {
  description = "CloudFront ID"
  value       = aws_cloudfront_distribution.website_storage.id
}

output "github_actions_role_arn" {
  description = "IAM Role ARN assumed by GitHub Actions via OIDC"
  value       = aws_iam_role.github_actions.arn
}

output "github_actions_role_name" {
  description = "IAM Role name assumed by GitHub Actions via OIDC"
  value       = aws_iam_role.github_actions.name
}