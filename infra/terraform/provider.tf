provider "aws" {
  region                      = var.aws_region
  access_key                  = var.aws_access_key
  secret_key                  = var.aws_secret_key
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = var.localstack_endpoint
    s3  = var.localstack_endpoint
  }

  default_tags {
    tags = {
      Project     = "taskflow-api"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
