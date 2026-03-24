################################################################################
# Terraform Backend Configuration
# Remote state stored in S3 with DynamoDB locking.
# Run scripts/setup-backend.sh BEFORE `terraform init` to provision these
# resources if they do not already exist.
################################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }

  # ── Remote backend ─────────────────────────────────────────────────────────
  # Update bucket / region / table to match what setup-backend.sh created.
  backend "s3" {
    bucket         = "dce042-tf-state-731961417222"
    key            = "dce042/assessment1/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "dce042-tf-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Assessment  = "DCE04.2-Assessment1"
    }
  }
}
