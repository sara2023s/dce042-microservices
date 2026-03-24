################################################################################
# Root Outputs – DCE 04.2 Assessment 1
################################################################################

# ── Networking ────────────────────────────────────────────────────────────────
output "vpc_id" {
  description = "ID of the dedicated VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (one per AZ)"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (one per AZ)"
  value       = module.networking.private_subnet_ids
}

output "alb_security_group_id" {
  description = "Security Group ID assigned to both ALBs"
  value       = module.networking.alb_security_group_id
}

output "ecs_security_group_id" {
  description = "Security Group ID assigned to ECS tasks"
  value       = module.networking.ecs_security_group_id
}

# ── ECR ───────────────────────────────────────────────────────────────────────
output "service_a_ecr_repo_url" {
  description = "ECR repository URL for the Product Service"
  value       = module.ecr.service_a_repo_url
}

output "service_b_ecr_repo_url" {
  description = "ECR repository URL for the Order Service"
  value       = module.ecr.service_b_repo_url
}

# ── ECS ───────────────────────────────────────────────────────────────────────
output "ecs_cluster_name" {
  description = "Name of the ECS Fargate cluster"
  value       = module.ecs.cluster_name
}

output "service_a_ecs_service_name" {
  description = "ECS service name for the Product Service"
  value       = module.ecs.service_a_name
}

output "service_b_ecs_service_name" {
  description = "ECS service name for the Order Service"
  value       = module.ecs.service_b_name
}

# ── ALB ───────────────────────────────────────────────────────────────────────
output "service_a_alb_dns_name" {
  description = "DNS name of the Product Service ALB"
  value       = module.alb.service_a_alb_dns
}

output "service_b_alb_dns_name" {
  description = "DNS name of the Order Service ALB"
  value       = module.alb.service_b_alb_dns
}

# ── Storage ───────────────────────────────────────────────────────────────────
output "artifacts_bucket_name" {
  description = "S3 bucket used by CodePipeline for build artifacts"
  value       = module.storage.artifacts_bucket_id
}

output "assets_bucket_name" {
  description = "S3 bucket used for application static assets"
  value       = module.storage.assets_bucket_name
}

output "dynamodb_table_name" {
  description = "DynamoDB table for application data"
  value       = module.storage.dynamodb_table_name
}

output "sns_topic_arn" {
  description = "SNS topic ARN for critical notifications"
  value       = module.storage.sns_topic_arn
}

# ── CI/CD ─────────────────────────────────────────────────────────────────────
output "codepipeline_name" {
  description = "Name of the CodePipeline"
  value       = module.cicd.codepipeline_name
}

output "codebuild_service_a_name" {
  description = "CodeBuild project name for service A"
  value       = module.cicd.codebuild_service_a_name
}

output "codebuild_service_b_name" {
  description = "CodeBuild project name for service B"
  value       = module.cicd.codebuild_service_b_name
}

# ── Federation ────────────────────────────────────────────────────────────────
output "saml_provider_arn" {
  description = "ARN of the AWS IAM SAML provider for Azure Entra ID"
  value       = module.federation.saml_provider_arn
}

output "devops_engineer_role_arn" {
  description = "IAM role ARN for Entra ID DevOpsEngineer group"
  value       = module.federation.devops_engineer_role_arn
}

output "readonly_auditor_role_arn" {
  description = "IAM role ARN for Entra ID ReadOnlyAuditor group"
  value       = module.federation.readonly_auditor_role_arn
}
