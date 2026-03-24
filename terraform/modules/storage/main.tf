################################################################################
# Storage Module
# Creates: CodePipeline artifacts S3 bucket, application assets S3 bucket,
#          DynamoDB table (application data), and SNS topic (notifications).
################################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ── S3: CodePipeline Artifacts Bucket ─────────────────────────────────────────
resource "aws_s3_bucket" "artifacts" {
  bucket        = "${local.name_prefix}-pipeline-artifacts-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = { Name = "${local.name_prefix}-pipeline-artifacts", Purpose = "CodePipelineArtifacts" }
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── S3: Application Assets Bucket ─────────────────────────────────────────────
resource "aws_s3_bucket" "assets" {
  bucket        = "${local.name_prefix}-app-assets-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = { Name = "${local.name_prefix}-app-assets", Purpose = "ApplicationAssets" }
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Public-read block – adjust if static website hosting is needed
resource "aws_s3_bucket_public_access_block" "assets" {
  bucket                  = aws_s3_bucket.assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── DynamoDB Table ────────────────────────────────────────────────────────────
resource "aws_dynamodb_table" "app_data" {
  name         = "${local.name_prefix}-app-data"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = { Name = "${local.name_prefix}-app-data", Purpose = "ApplicationData" }
}

# ── SNS Topic for Critical Notifications ──────────────────────────────────────
resource "aws_sns_topic" "notifications" {
  name = "${local.name_prefix}-notifications"

  tags = { Name = "${local.name_prefix}-notifications" }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
