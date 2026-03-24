#!/usr/bin/env bash
# =============================================================================
# setup-backend.sh
# Creates the S3 bucket and DynamoDB table required for Terraform remote state
# BEFORE running `terraform init`.
#
# Usage:
#   chmod +x scripts/setup-backend.sh
#   ./scripts/setup-backend.sh
# =============================================================================

set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
BUCKET="${TF_STATE_BUCKET:-dce042-tf-state}"
TABLE="${TF_STATE_TABLE:-dce042-tf-state-lock}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "=========================================="
echo " Terraform Backend Setup"
echo " Region  : $REGION"
echo " Bucket  : $BUCKET"
echo " Table   : $TABLE"
echo " Account : $ACCOUNT_ID"
echo "=========================================="

# ── S3 Bucket ──────────────────────────────────────────────────────────────────
if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "[OK] S3 bucket '$BUCKET' already exists."
else
  echo "[+] Creating S3 bucket '$BUCKET'..."
  if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "$BUCKET" --region "$REGION"
  else
    aws s3api create-bucket \
      --bucket "$BUCKET" \
      --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi

  # Enable versioning so state history is preserved
  aws s3api put-bucket-versioning \
    --bucket "$BUCKET" \
    --versioning-configuration Status=Enabled

  # Enable server-side encryption
  aws s3api put-bucket-encryption \
    --bucket "$BUCKET" \
    --server-side-encryption-configuration '{
      "Rules": [{
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }]
    }'

  # Block all public access
  aws s3api put-public-access-block \
    --bucket "$BUCKET" \
    --public-access-block-configuration \
      BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

  echo "[OK] S3 bucket created and configured."
fi

# ── DynamoDB Table ─────────────────────────────────────────────────────────────
if aws dynamodb describe-table --table-name "$TABLE" --region "$REGION" 2>/dev/null; then
  echo "[OK] DynamoDB table '$TABLE' already exists."
else
  echo "[+] Creating DynamoDB table '$TABLE'..."
  aws dynamodb create-table \
    --table-name "$TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION"

  echo "[OK] DynamoDB table created."
fi

echo ""
echo "=========================================="
echo " Backend setup complete!"
echo " Next steps:"
echo "   cd terraform"
echo "   terraform init"
echo "   cp terraform.tfvars.example terraform.tfvars"
echo "   # Edit terraform.tfvars with your values"
echo "   terraform plan"
echo "   terraform apply"
echo "=========================================="
