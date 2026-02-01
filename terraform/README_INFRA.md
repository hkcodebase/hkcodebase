
# Website hosting infrastructure: S3 + CloudFront (OAC) + GitHub Actions deploy (OIDC)

This readme covers:
- Creating the website hosting infrastructure using Terraform:
    - S3 private bucket
    - CloudFront distribution
    - OAC (Origin Access Control)
    - bucket policy allowing reads only from CloudFront
- GitHub Actions deployment:
    - upload to S3
    - invalidate CloudFront cache
    - authentication via OIDC (no AWS keys)

---

## 1) Configure Terraform variables

Create `terraform.tfvars` in the `terraform/` directory (example):
`aws_region = "us-east-1" project_name = "portfolio" github_username = "<YOUR_GITHUB_USERNAME>" repo_name = "<YOUR_REPO_NAME>"`


---

## 2) Create infrastructure with Terraform

From the `terraform/` directory:

Init: `terraform init`  
Apply: `terraform apply`

After completion, note the Terraform outputs (you will use them in GitHub Actions), typically including:
- S3 bucket name
- CloudFront distribution ID
- IAM role ARN for GitHub Actions (OIDC assume-role)
- CloudFront URL

---

## 3) Deployment is done via GitHub Actions (S3 copy + CloudFront invalidation)

In this repo:
- S3 upload + cache invalidation: `.github/workflows/main.yml`
- OIDC provider + IAM role/policy used by that workflow: `terraform/main.tf`

### Configure GitHub Environment + Variables

The workflow uses `environment: prod`.

In GitHub:
1. Create an environment named: `prod`
2. Add environment/repo variables expected by the workflow:
    - `AWS_ROLE_ARN` = `<ROLE_ARN_FROM_TERRAFORM_OUTPUT>`
    - `S3_BUCKET_NAME` = `<S3_BUCKET_NAME_FROM_TERRAFORM_OUTPUT>`
    - `CLOUDFRONT_DISTRIBUTION_ID` = `<DISTRIBUTION_ID_FROM_TERRAFORM_OUTPUT>`

> Do not add AWS access keys—OIDC is used.

---

## 4) Update site content and deploy

Update your website file(s) and push according to the workflow trigger rules. Then check GitHub Actions logs to confirm:
- upload to S3 succeeded
- CloudFront invalidation succeeded

---

## 5) Verify

Open the CloudFront URL from Terraform outputs in a browser.

---

## Cleanup

Destroy infra: `terraform destroy`

## References
1. for github actions OIDC with AWS:
https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services

2. thumbprint_list generation steps 
   - Get the certificate chain:
   ```bash
   echo | openssl s_client -servername token.actions.githubusercontent.com -connect token.actions.githubusercontent.com:443 -showcerts 2>/dev/null
   ```
   - From that output, identify the root CA certificate (the last cert in the chain), save it to a file (e.g., root-ca.pem), then compute the SHA‑1 fingerprint:
   ```bash 
   openssl x509 -in root-ca.pem -noout -fingerprint -sha1
   ```
   - Convert it into IAM’s expected format (same hex, but no colons, lowercase), and put it in thumbprint_list.