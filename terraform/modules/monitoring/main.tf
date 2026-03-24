################################################################################
# Monitoring Module
# Creates: Application Auto Scaling targets, 4 scaling policies (2 scale-out,
#          2 scale-in), 4 CloudWatch alarms (2 high-CPU, 2 low-CPU), and a
#          CloudWatch dashboard.
################################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ── Autoscaling: Service A ────────────────────────────────────────────────────
resource "aws_appautoscaling_target" "service_a" {
  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${var.ecs_cluster_name}/${local.name_prefix}-${var.service_a_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Scale-OUT policy – Service A
resource "aws_appautoscaling_policy" "service_a_scale_out" {
  name               = "${local.name_prefix}-${var.service_a_name}-scale-out"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.service_a.resource_id
  scalable_dimension = aws_appautoscaling_target.service_a.scalable_dimension
  service_namespace  = aws_appautoscaling_target.service_a.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      scaling_adjustment          = 1
      metric_interval_lower_bound = 0
    }
  }
}

# Scale-IN policy – Service A
resource "aws_appautoscaling_policy" "service_a_scale_in" {
  name               = "${local.name_prefix}-${var.service_a_name}-scale-in"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.service_a.resource_id
  scalable_dimension = aws_appautoscaling_target.service_a.scalable_dimension
  service_namespace  = aws_appautoscaling_target.service_a.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      scaling_adjustment          = -1
      metric_interval_upper_bound = 0
    }
  }
}

# HIGH-CPU Alarm → triggers scale-out for Service A
resource "aws_cloudwatch_metric_alarm" "service_a_high_cpu" {
  alarm_name          = "${local.name_prefix}-${var.service_a_name}-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.cpu_scale_out_threshold
  alarm_description   = "Scale OUT ${var.service_a_name} when CPU >= ${var.cpu_scale_out_threshold}%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = "${local.name_prefix}-${var.service_a_name}"
  }

  alarm_actions = [
    aws_appautoscaling_policy.service_a_scale_out.arn,
    var.sns_topic_arn
  ]

  tags = { Name = "${local.name_prefix}-${var.service_a_name}-high-cpu" }
}

# LOW-CPU Alarm → triggers scale-in for Service A
resource "aws_cloudwatch_metric_alarm" "service_a_low_cpu" {
  alarm_name          = "${local.name_prefix}-${var.service_a_name}-low-cpu"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.cpu_scale_in_threshold
  alarm_description   = "Scale IN ${var.service_a_name} when CPU <= ${var.cpu_scale_in_threshold}%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = "${local.name_prefix}-${var.service_a_name}"
  }

  alarm_actions = [aws_appautoscaling_policy.service_a_scale_in.arn]

  tags = { Name = "${local.name_prefix}-${var.service_a_name}-low-cpu" }
}

# ── Autoscaling: Service B ────────────────────────────────────────────────────
resource "aws_appautoscaling_target" "service_b" {
  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${var.ecs_cluster_name}/${local.name_prefix}-${var.service_b_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Scale-OUT policy – Service B
resource "aws_appautoscaling_policy" "service_b_scale_out" {
  name               = "${local.name_prefix}-${var.service_b_name}-scale-out"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.service_b.resource_id
  scalable_dimension = aws_appautoscaling_target.service_b.scalable_dimension
  service_namespace  = aws_appautoscaling_target.service_b.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      scaling_adjustment          = 1
      metric_interval_lower_bound = 0
    }
  }
}

# Scale-IN policy – Service B
resource "aws_appautoscaling_policy" "service_b_scale_in" {
  name               = "${local.name_prefix}-${var.service_b_name}-scale-in"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.service_b.resource_id
  scalable_dimension = aws_appautoscaling_target.service_b.scalable_dimension
  service_namespace  = aws_appautoscaling_target.service_b.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      scaling_adjustment          = -1
      metric_interval_upper_bound = 0
    }
  }
}

# HIGH-CPU Alarm → triggers scale-out for Service B
resource "aws_cloudwatch_metric_alarm" "service_b_high_cpu" {
  alarm_name          = "${local.name_prefix}-${var.service_b_name}-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.cpu_scale_out_threshold
  alarm_description   = "Scale OUT ${var.service_b_name} when CPU >= ${var.cpu_scale_out_threshold}%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = "${local.name_prefix}-${var.service_b_name}"
  }

  alarm_actions = [
    aws_appautoscaling_policy.service_b_scale_out.arn,
    var.sns_topic_arn
  ]

  tags = { Name = "${local.name_prefix}-${var.service_b_name}-high-cpu" }
}

# LOW-CPU Alarm → triggers scale-in for Service B
resource "aws_cloudwatch_metric_alarm" "service_b_low_cpu" {
  alarm_name          = "${local.name_prefix}-${var.service_b_name}-low-cpu"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.cpu_scale_in_threshold
  alarm_description   = "Scale IN ${var.service_b_name} when CPU <= ${var.cpu_scale_in_threshold}%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = "${local.name_prefix}-${var.service_b_name}"
  }

  alarm_actions = [aws_appautoscaling_policy.service_b_scale_in.arn]

  tags = { Name = "${local.name_prefix}-${var.service_b_name}-low-cpu" }
}

# ── CloudWatch Dashboard ──────────────────────────────────────────────────────
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title   = "ECS CPU Utilisation"
          region  = var.aws_region
          period  = 60
          stat    = "Average"
          view    = "timeSeries"
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", "${local.name_prefix}-${var.service_a_name}", { "label" : "Service A CPU" }],
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", "${local.name_prefix}-${var.service_b_name}", { "label" : "Service B CPU" }]
          ]
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title   = "ECS Memory Utilisation"
          region  = var.aws_region
          period  = 60
          stat    = "Average"
          view    = "timeSeries"
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", "${local.name_prefix}-${var.service_a_name}", { "label" : "Service A Memory" }],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", "${local.name_prefix}-${var.service_b_name}", { "label" : "Service B Memory" }]
          ]
        }
      },
      {
        type   = "alarm"
        width  = 24
        height = 4
        properties = {
          title  = "Scaling Alarms"
          alarms = [
            aws_cloudwatch_metric_alarm.service_a_high_cpu.arn,
            aws_cloudwatch_metric_alarm.service_a_low_cpu.arn,
            aws_cloudwatch_metric_alarm.service_b_high_cpu.arn,
            aws_cloudwatch_metric_alarm.service_b_low_cpu.arn
          ]
        }
      }
    ]
  })
}
