# Setup Terraform with AWS CLI

## 1. Install Terraform
Before you begin, ensure you have Terraform installed on your machine. 
Terraform official documentation to download and install Terraform: https://developer.hashicorp.com/terraform/install

Verify the installation by running `terraform -version`
## 2. AWS CLI Configuration

 - Install AWS CLI on your machine. refer to https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
 - Create an IAM role in your AWS account for Terraform with least privilige to create resources 
 - Create a new user for terraform and assign the IAM role created above
 - Generate an access key and secret key for this user and configure in aws cli using aws configure command 
 - Run command `terraform init` 
 - Run command `terraform apply`
 - Run command `terraform destroy`

For S3 as backend configuration 
- create s3 bucket terraform-state-<AWS_ACCOUNT_ID>
- run below command to configure backend

  `AWS_PROFILE=tf-local AWS_SDK_LOAD_CONFIG=1 terraform init -reconfigure \
   -backend-config="bucket=terraform-state-<AWS_ACCOUNT_ID>" \
   -backend-config="key=hemantkumar-dev/terraform.tfstate" \
   -backend-config="region=us-east-1" `
- Now run command with aws profile tf-local
    `AWS_PROFILE=tf-local AWS_SDK_LOAD_CONFIG=1 terraform apply`

* Note: use command to check backend configuration `cat .terraform/terraform.tfstate`

# Verify the Deployment

Once `terraform apply` completes, it will display the `website_cloudfront_url`. 

1. Copy your portfolio `index.html` into generated s3 bucket `website_s3_bucket_name`.
2. Open `website_cloudfront_url` in web browser.

# Cleanup

To avoid ongoing AWS charges, destroy the infrastructure once you are finished testing:

1. Run the destroy command:
   ```bash
   terraform destroy
   ```
2. Review the plan and type `yes` to confirm the deletion of all resources.

# [Terraform TF file](terraform.tf)

#### Version explanation from [terraform.tf](terraform.tf)
The string ~> 5.92 means your configuration supports any version of the provider with a major version of 5 and a minor version greater than or equal to 92

The string >= 1.2 means your configuration supports any version of Terraform greater than or equal to 1.2.
