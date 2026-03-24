################################################################################
# ECS Module
# Creates: ECS Cluster, CloudWatch Log Groups, two Task Definitions (Fargate),
#          and two ECS Services deployed across private HA subnets.
################################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ── ECS Cluster ───────────────────────────────────────────────────────────────
resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = { Name = "${local.name_prefix}-cluster" }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}

# ── CloudWatch Log Groups ─────────────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "service_a" {
  name              = "/ecs/${local.name_prefix}/${var.service_a_name}"
  retention_in_days = 30

  tags = { Name = "${local.name_prefix}-${var.service_a_name}-logs" }
}

resource "aws_cloudwatch_log_group" "service_b" {
  name              = "/ecs/${local.name_prefix}/${var.service_b_name}"
  retention_in_days = 30

  tags = { Name = "${local.name_prefix}-${var.service_b_name}-logs" }
}

# ── Task Definition: Service A ────────────────────────────────────────────────
resource "aws_ecs_task_definition" "service_a" {
  family                   = "${local.name_prefix}-${var.service_a_name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.service_a_cpu
  memory                   = var.service_a_memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.service_a_task_role_arn

  container_definitions = jsonencode([
    {
      name      = var.service_a_name
      image     = var.service_a_image
      essential = true

      portMappings = [
        {
          containerPort = var.service_a_container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "DYNAMODB_TABLE", value = var.dynamodb_table_name },
        { name = "ASSETS_BUCKET",  value = var.assets_bucket_name },
        { name = "AWS_REGION",     value = var.aws_region },
        { name = "PORT",           value = tostring(var.service_a_container_port) }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.service_a.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.service_a_container_port}/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = { Name = "${local.name_prefix}-${var.service_a_name}-taskdef" }
}

# ── Task Definition: Service B ────────────────────────────────────────────────
resource "aws_ecs_task_definition" "service_b" {
  family                   = "${local.name_prefix}-${var.service_b_name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.service_b_cpu
  memory                   = var.service_b_memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.service_b_task_role_arn

  container_definitions = jsonencode([
    {
      name      = var.service_b_name
      image     = var.service_b_image
      essential = true

      portMappings = [
        {
          containerPort = var.service_b_container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "DYNAMODB_TABLE", value = var.dynamodb_table_name },
        { name = "AWS_REGION",     value = var.aws_region },
        { name = "PORT",           value = tostring(var.service_b_container_port) }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.service_b.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.service_b_container_port}/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = { Name = "${local.name_prefix}-${var.service_b_name}-taskdef" }
}

# ── ECS Service: Service A ────────────────────────────────────────────────────
resource "aws_ecs_service" "service_a" {
  name                               = "${local.name_prefix}-${var.service_a_name}"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.service_a.arn
  desired_count                      = var.service_a_desired_count
  launch_type                        = "FARGATE"
  health_check_grace_period_seconds  = 60
  enable_execute_command             = true

  # Blue/Green deployments are handled by CodeDeploy, so use EXTERNAL controller
  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.service_a_tg_arn
    container_name   = var.service_a_name
    container_port   = var.service_a_container_port
  }

  lifecycle {
    # CodeDeploy manages task_definition and load_balancer after first deploy
    ignore_changes = [task_definition, load_balancer]
  }

  tags = { Name = "${local.name_prefix}-${var.service_a_name}" }
}

# ── ECS Service: Service B ────────────────────────────────────────────────────
resource "aws_ecs_service" "service_b" {
  name                               = "${local.name_prefix}-${var.service_b_name}"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.service_b.arn
  desired_count                      = var.service_b_desired_count
  launch_type                        = "FARGATE"
  health_check_grace_period_seconds  = 60
  enable_execute_command             = true

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.service_b_tg_arn
    container_name   = var.service_b_name
    container_port   = var.service_b_container_port
  }

  lifecycle {
    ignore_changes = [task_definition, load_balancer]
  }

  tags = { Name = "${local.name_prefix}-${var.service_b_name}" }
}
