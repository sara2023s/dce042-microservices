################################################################################
# Root Module – DCE 04.2 Assessment 1
# Calls every child module in dependency order.
################################################################################

# ── 1. Networking ─────────────────────────────────────────────────────────────
module "networking" {
  source = "./modules/networking"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

# ── 2. IAM Roles & Policies ───────────────────────────────────────────────────
module "iam" {
  source = "./modules/iam"

  project_name    = var.project_name
  environment     = var.environment
  aws_region      = var.aws_region
  artifacts_bucket_arn = module.storage.artifacts_bucket_arn
  assets_bucket_arn    = module.storage.assets_bucket_arn
  ecr_repo_arns        = [module.ecr.service_a_repo_arn, module.ecr.service_b_repo_arn]
}

# ── 3. ECR Repositories ───────────────────────────────────────────────────────
module "ecr" {
  source = "./modules/ecr"

  project_name   = var.project_name
  environment    = var.environment
  service_a_name = var.service_a_name
  service_b_name = var.service_b_name
}

# ── 4. Storage (S3 + DynamoDB + SNS) ─────────────────────────────────────────
module "storage" {
  source = "./modules/storage"

  project_name  = var.project_name
  environment   = var.environment
  alert_email   = var.alert_email
}

# ── 5. Application Load Balancers ─────────────────────────────────────────────
module "alb" {
  source = "./modules/alb"

  project_name         = var.project_name
  environment          = var.environment
  vpc_id               = module.networking.vpc_id
  public_subnet_ids    = module.networking.public_subnet_ids
  alb_security_group_id = module.networking.alb_security_group_id
  service_a_name       = var.service_a_name
  service_b_name       = var.service_b_name
  service_a_port       = var.service_a_container_port
  service_b_port       = var.service_b_container_port
  acm_certificate_arn  = var.acm_certificate_arn
}

# ── 6. ECS Cluster, Task Definitions, and Services ───────────────────────────
module "ecs" {
  source = "./modules/ecs"

  project_name              = var.project_name
  environment               = var.environment
  aws_region                = var.aws_region
  vpc_id                    = module.networking.vpc_id
  private_subnet_ids        = module.networking.private_subnet_ids
  ecs_security_group_id     = module.networking.ecs_security_group_id
  service_a_name            = var.service_a_name
  service_b_name            = var.service_b_name
  service_a_image           = "${module.ecr.service_a_repo_url}:latest"
  service_b_image           = "${module.ecr.service_b_repo_url}:latest"
  service_a_cpu             = var.service_a_cpu
  service_a_memory          = var.service_a_memory
  service_b_cpu             = var.service_b_cpu
  service_b_memory          = var.service_b_memory
  service_a_container_port  = var.service_a_container_port
  service_b_container_port  = var.service_b_container_port
  service_a_desired_count   = var.service_a_desired_count
  service_b_desired_count   = var.service_b_desired_count
  service_a_tg_arn          = module.alb.service_a_tg_arn
  service_b_tg_arn          = module.alb.service_b_tg_arn
  task_execution_role_arn   = module.iam.ecs_task_execution_role_arn
  service_a_task_role_arn   = module.iam.service_a_task_role_arn
  service_b_task_role_arn   = module.iam.service_b_task_role_arn
  dynamodb_table_name       = module.storage.dynamodb_table_name
  assets_bucket_name        = module.storage.assets_bucket_name
}

# ── 7. Autoscaling & Monitoring ───────────────────────────────────────────────
module "monitoring" {
  source = "./modules/monitoring"

  project_name             = var.project_name
  environment              = var.environment
  aws_region               = var.aws_region
  ecs_cluster_name         = module.ecs.cluster_name
  service_a_name           = var.service_a_name
  service_b_name           = var.service_b_name
  autoscaling_min_capacity = var.autoscaling_min_capacity
  autoscaling_max_capacity = var.autoscaling_max_capacity
  cpu_scale_out_threshold  = var.cpu_scale_out_threshold
  cpu_scale_in_threshold   = var.cpu_scale_in_threshold
  sns_topic_arn            = module.storage.sns_topic_arn
}

# ── 8. CI/CD Pipeline ─────────────────────────────────────────────────────────
module "cicd" {
  source = "./modules/cicd"

  project_name            = var.project_name
  environment             = var.environment
  aws_region              = var.aws_region
  service_a_name          = var.service_a_name
  service_b_name          = var.service_b_name
  service_a_ecr_repo_url  = module.ecr.service_a_repo_url
  service_b_ecr_repo_url  = module.ecr.service_b_repo_url
  service_a_ecr_repo_arn  = module.ecr.service_a_repo_arn
  service_b_ecr_repo_arn  = module.ecr.service_b_repo_arn
  artifacts_bucket_id     = module.storage.artifacts_bucket_id
  artifacts_bucket_arn    = module.storage.artifacts_bucket_arn
  ecs_cluster_name        = module.ecs.cluster_name
  service_a_ecs_svc_name  = module.ecs.service_a_name
  service_b_ecs_svc_name  = module.ecs.service_b_name
  alb_service_a_listener_arn     = module.alb.service_a_listener_arn
  alb_service_b_listener_arn     = module.alb.service_b_listener_arn
  service_a_tg_blue_arn          = module.alb.service_a_tg_arn
  service_b_tg_blue_arn          = module.alb.service_b_tg_arn
  codebuild_role_arn      = module.iam.codebuild_role_arn
  codedeploy_role_arn     = module.iam.codedeploy_role_arn
  codepipeline_role_arn   = module.iam.codepipeline_role_arn
  github_owner            = var.github_owner
  github_repo             = var.github_repo
  github_branch           = var.github_branch
  codestar_connection_arn = var.codestar_connection_arn
  sns_topic_arn           = module.storage.sns_topic_arn
}

# ── 9. Azure Entra ID SAML Federation ────────────────────────────────────────
module "federation" {
  source = "./modules/federation"

  project_name            = var.project_name
  environment             = var.environment
  entra_saml_metadata_url = var.entra_saml_metadata_url
  entra_saml_metadata_xml = var.entra_saml_metadata_xml
}
