################################################################################
# CI/CD Module
# Creates: 2 CodeBuild projects, 2 CodeDeploy applications + deployment groups
#          (Blue/Green ECS), and 1 CodePipeline with parallel Build & Deploy.
################################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

data "aws_caller_identity" "current" {}

# ── CodeBuild: Service A ──────────────────────────────────────────────────────
resource "aws_codebuild_project" "service_a" {
  name          = "${local.name_prefix}-build-${var.service_a_name}"
  description   = "Build and push Docker image for ${var.service_a_name}"
  build_timeout = 20
  service_role  = var.codebuild_role_arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true   # Required for Docker builds

    environment_variable {
      name  = "ECR_REPO_URL"
      value = var.service_a_ecr_repo_url
    }
    environment_variable {
      name  = "SERVICE_NAME"
      value = var.service_a_name
    }
    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "microservices/${var.service_a_name}/buildspec.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${local.name_prefix}-${var.service_a_name}"
      stream_name = "build"
    }
  }

  tags = { Name = "${local.name_prefix}-build-${var.service_a_name}" }
}

# ── CodeBuild: Service B ──────────────────────────────────────────────────────
resource "aws_codebuild_project" "service_b" {
  name          = "${local.name_prefix}-build-${var.service_b_name}"
  description   = "Build and push Docker image for ${var.service_b_name}"
  build_timeout = 20
  service_role  = var.codebuild_role_arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "ECR_REPO_URL"
      value = var.service_b_ecr_repo_url
    }
    environment_variable {
      name  = "SERVICE_NAME"
      value = var.service_b_name
    }
    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "microservices/${var.service_b_name}/buildspec.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${local.name_prefix}-${var.service_b_name}"
      stream_name = "build"
    }
  }

  tags = { Name = "${local.name_prefix}-build-${var.service_b_name}" }
}

# ── CodeDeploy: Service A ─────────────────────────────────────────────────────
resource "aws_codedeploy_app" "service_a" {
  name             = "${local.name_prefix}-deploy-${var.service_a_name}"
  compute_platform = "ECS"

  tags = { Name = "${local.name_prefix}-deploy-${var.service_a_name}" }
}

resource "aws_codedeploy_deployment_group" "service_a" {
  app_name               = aws_codedeploy_app.service_a.name
  deployment_group_name  = "${local.name_prefix}-dg-${var.service_a_name}"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = var.codedeploy_role_arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.service_a_ecs_svc_name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.alb_service_a_listener_arn]
      }
      target_group { name = split("/", split(":", var.service_a_tg_blue_arn)[5])[1] }
      target_group { name = "${local.name_prefix}-tg-a-green" }
    }
  }

  tags = { Name = "${local.name_prefix}-dg-${var.service_a_name}" }
}

# ── CodeDeploy: Service B ─────────────────────────────────────────────────────
resource "aws_codedeploy_app" "service_b" {
  name             = "${local.name_prefix}-deploy-${var.service_b_name}"
  compute_platform = "ECS"

  tags = { Name = "${local.name_prefix}-deploy-${var.service_b_name}" }
}

resource "aws_codedeploy_deployment_group" "service_b" {
  app_name               = aws_codedeploy_app.service_b.name
  deployment_group_name  = "${local.name_prefix}-dg-${var.service_b_name}"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = var.codedeploy_role_arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.service_b_ecs_svc_name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.alb_service_b_listener_arn]
      }
      target_group { name = split("/", split(":", var.service_b_tg_blue_arn)[5])[1] }
      target_group { name = "${local.name_prefix}-tg-b-green" }
    }
  }

  tags = { Name = "${local.name_prefix}-dg-${var.service_b_name}" }
}

# ── CodePipeline ──────────────────────────────────────────────────────────────
# Pipeline: Source → Parallel Builds → Parallel Blue/Green Deploys
# Only created once a valid CodeStar connection ARN is provided.
resource "aws_codepipeline" "main" {
  count    = var.codestar_connection_arn != "" ? 1 : 0
  name     = "${local.name_prefix}-pipeline"
  role_arn = var.codepipeline_role_arn

  artifact_store {
    location = var.artifacts_bucket_id
    type     = "S3"
  }

  # Stage 1 – Source (GitHub via CodeStar Connection)
  stage {
    name = "Source"

    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn        = var.codestar_connection_arn
        FullRepositoryId     = "${var.github_owner}/${var.github_repo}"
        BranchName           = var.github_branch
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
      }
    }
  }

  # Stage 2 – Parallel Builds (Service A and Service B simultaneously)
  stage {
    name = "Build"

    action {
      name             = "Build_${var.service_a_name}"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output_a"]
      run_order        = 1

      configuration = {
        ProjectName = aws_codebuild_project.service_a.name
      }
    }

    action {
      name             = "Build_${var.service_b_name}"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output_b"]
      run_order        = 1   # Same run_order = parallel execution

      configuration = {
        ProjectName = aws_codebuild_project.service_b.name
      }
    }
  }

  # Stage 3 – Parallel Blue/Green Deploys
  stage {
    name = "Deploy"

    action {
      name            = "Deploy_${var.service_a_name}"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      version         = "1"
      input_artifacts = ["build_output_a"]
      run_order       = 1

      configuration = {
        ApplicationName                = aws_codedeploy_app.service_a.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.service_a.deployment_group_name
        TaskDefinitionTemplateArtifact = "build_output_a"
        TaskDefinitionTemplatePath     = "taskdef.json"
        AppSpecTemplateArtifact        = "build_output_a"
        AppSpecTemplatePath            = "appspec.yml"
      }
    }

    action {
      name            = "Deploy_${var.service_b_name}"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      version         = "1"
      input_artifacts = ["build_output_b"]
      run_order       = 1   # Same run_order = parallel deployment

      configuration = {
        ApplicationName                = aws_codedeploy_app.service_b.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.service_b.deployment_group_name
        TaskDefinitionTemplateArtifact = "build_output_b"
        TaskDefinitionTemplatePath     = "taskdef.json"
        AppSpecTemplateArtifact        = "build_output_b"
        AppSpecTemplatePath            = "appspec.yml"
      }
    }
  }

  tags = { Name = "${local.name_prefix}-pipeline" }
}
