# Setup: Terraform CLI setup, remote state (S3 backend), and Identity Center “terraform user” (CLI)

This Readme file covers setup steps for:
- Terraform initialization basics
- Create and configuring an S3 backend to manage terraform state
- IAM Identity Center setup for a terraform user (using IAM Identity Center user, group, permission set) with AWS CLI Commands

---

## Prerequisites

Installed Terraform: `terraform -version`  
Installed AWS CLI v2: `aws --version`

---

## AWS CLI authentication model

You’ll typically have:
- AWS CLI profile (used once to enable/configure Identity Center and create users/groups/permission sets), e.g. `admin`
- `terraform operator` profile that uses SSO for Terraform work: `tf-local`

---

## First-time AWS login (admin) + ensure Identity Center exists

### 0) Set regions and admin profile

Set environment variables (optional):  
`export AWS_PROFILE_ADMIN="admin"`  
`export SSO_REGION="us-east-1"`  
`export AWS_REGION="us-east-1"`

### 1) Verify you can access AWS as admin

`aws sts get-caller-identity --profile "$AWS_PROFILE_ADMIN"`

### 2) Check whether IAM Identity Center is already enabled

`aws sso-admin list-instances --region "$SSO_REGION" --profile "$AWS_PROFILE_ADMIN"`

- If this returns an instance: continue to the next section.
- If it returns no instances: IAM Identity Center is not enabled yet.

### 3) If Identity Center is not enabled (first time only)

IAM Identity Center enablement is typically done via AWS Console (it’s a service-level setup step).

Do this once:
1. AWS Console → **IAM Identity Center** → **Enable**
2. Choose the Identity Center region (this should match `SSO_REGION`)
3. After it’s enabled, re-run:  
   `aws sso-admin list-instances --region "$SSO_REGION" --profile "$AWS_PROFILE_ADMIN"`

---

## Identity Center (SSO): create permission set, group, and “terraform user” (CLI)

### 1) Discover Identity Center instance

`aws sso-admin list-instances --region "$SSO_REGION" --profile "$AWS_PROFILE_ADMIN"`

From output, capture:
- `InstanceArn` → `<SSO_INSTANCE_ARN>`
- `IdentityStoreId` → `<IDENTITY_STORE_ID>`

### 2) Create a Permission Set for Terraform

`aws sso-admin create-permission-set --instance-arn "<SSO_INSTANCE_ARN>" --name "TerraformProvisioner" --description "Permissions for Terraform to provision infra" --session-duration "PT8H" --region "$SSO_REGION" --profile "$AWS_PROFILE_ADMIN"`

Capture returned:
- `PermissionSetArn` → `<PERMISSION_SET_ARN>`

### 3) Attach permissions to the Permission Set

Quick-start (broad permissions) example (tighten later):

`aws sso-admin attach-managed-policy-to-permission-set --instance-arn "<SSO_INSTANCE_ARN>" --permission-set-arn "<PERMISSION_SET_ARN>" --managed-policy-arn "arn:aws:iam::aws:policy/AdministratorAccess" --region "$SSO_REGION" --profile "$AWS_PROFILE_ADMIN"`

### 4) Create a Group

`aws identitystore create-group --identity-store-id "<IDENTITY_STORE_ID>" --display-name "terraform-admins" --description "Users allowed to run Terraform" --region "$SSO_REGION" --profile "$AWS_PROFILE_ADMIN"`

Capture:
- `GroupId` → `<GROUP_ID>`

### 5) Create a User (“terraform user”)

`aws identitystore create-user --identity-store-id "<IDENTITY_STORE_ID>" --user-name "terraform.user" --name "GivenName=Terraform,FamilyName=User" --display-name "Terraform User" --emails "Value=<TERRAFORM_USER_EMAIL>,Type=Work,Primary=true" --region "$SSO_REGION" --profile "$AWS_PROFILE_ADMIN"`

Capture:
- `UserId` → `<USER_ID>`

### 6) Add the user to the group

`aws identitystore create-group-membership --identity-store-id "<IDENTITY_STORE_ID>" --group-id "<GROUP_ID>" --member-id "UserId=<USER_ID>" --region "$SSO_REGION" --profile "$AWS_PROFILE_ADMIN"`

### 7) Assign the Permission Set to the group for your AWS account

Get account id:

`aws sts get-caller-identity --profile "$AWS_PROFILE_ADMIN"`

Set:
- `<AWS_ACCOUNT_ID>`

Create assignment:

`aws sso-admin create-account-assignment --instance-arn "<SSO_INSTANCE_ARN>" --target-id "<AWS_ACCOUNT_ID>" --target-type "AWS_ACCOUNT" --permission-set-arn "<PERMISSION_SET_ARN>" --principal-type "GROUP" --principal-id "<GROUP_ID>" --region "$SSO_REGION" --profile "$AWS_PROFILE_ADMIN"`

Provision (important after policy/assignment changes):

`aws sso-admin provision-permission-set --instance-arn "<SSO_INSTANCE_ARN>" --permission-set-arn "<PERMISSION_SET_ARN>" --target-type "AWS_ACCOUNT" --region "$SSO_REGION" --profile "$AWS_PROFILE_ADMIN"`

### 8) Configure AWS CLI SSO profile for Terraform usage (profile name: `tf-local`)

Run: `aws configure sso`

When prompted, use:
- SSO start URL: `<YOUR_IDENTITY_CENTER_START_URL>`
- SSO region: `"$SSO_REGION"`
- Account: `<AWS_ACCOUNT_ID>`
- Role/Permission set: `TerraformProvisioner`
- CLI profile name: `tf-local`

Then login: `aws sso login --profile tf-local`

Test: `aws sts get-caller-identity --profile tf-local`

---

## Remote state: S3 backend setup

### 1) Create an S3 bucket for Terraform state

Bucket name suggestion: `terraform-state-<AWS_ACCOUNT_ID>`

Example CLI:

`aws s3api create-bucket --bucket "terraform-state-<AWS_ACCOUNT_ID>" --region "$AWS_REGION" --profile tf-local`

> If you use regions other than `us-east-1`, `create-bucket` may require a `LocationConstraint`.

### 2) Reconfigure Terraform to use S3 backend

From the `terraform/` directory:

`AWS_PROFILE=tf-local AWS_SDK_LOAD_CONFIG=1 terraform init -reconfigure -backend-config="bucket=terraform-state-<AWS_ACCOUNT_ID>" -backend-config="key=<YOUR_PREFIX>/terraform.tfstate" -backend-config="region=<BACKEND_BUCKET_REGION>"`

### 3) Normal Terraform commands (with SSO profile `tf-local`)

Plan: `AWS_PROFILE=tf-local terraform plan`  
Apply: `AWS_PROFILE=tf-local terraform apply`

---

## Next step

Proceed to: `README_INFRA.md`