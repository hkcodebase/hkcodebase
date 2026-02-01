
# About

This directory contains the Infrastructure-as-Code for this project, managed with Terraform.
It provisions and configures the AWS resources used to host the static website and enable automated deployments using GitHub Actions.

## What this Terraform creates (high level)

- **S3 (private) bucket** for storing website assets
- **CloudFront distribution** in front of the bucket for HTTPS delivery and caching
- **Origin Access Control (OAC)** so CloudFront can read from the private bucket (no public S3 access)
- **IAM OIDC role for GitHub Actions** to deploy site files and trigger CloudFront invalidations (no long-lived AWS keys)

## How to use these docs

This directory has two focused guides:

1. **Terraform Setup (Terraform CLI + remote state + Identity Center “terraform user”)**  
   See: [Readme for Terraform Setup](README_TERRAFORM_SETUP.md)

2. **Website hosting infrastructure (S3 + CloudFront + OAC + GitHub Actions OIDC deploy flow)**  
   See: [Readme for Infra](README_INFRA.md)

## Outputs

After `apply`, key values (like the CloudFront URL/domain and the GitHub Actions role) are exposed via Terraform outputs.
See `outputs.tf` for the full list.

* This setup follows a “least privilege + private by default” approach (S3 is not publicly readable).
