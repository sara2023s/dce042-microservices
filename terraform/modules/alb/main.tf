################################################################################
# ALB Module
# Creates two public-facing Application Load Balancers, target groups,
# HTTP listeners (with optional HTTPS), and health checks.
################################################################################

locals {
  name_prefix   = "${var.project_name}-${var.environment}"
  enable_https  = var.acm_certificate_arn != ""
}

# ──────────────────────────────────────────────────────────────────────────────
# SERVICE A – ALB (Product Service)
# ──────────────────────────────────────────────────────────────────────────────
resource "aws_lb" "service_a" {
  name               = "${local.name_prefix}-alb-svc-a"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = { Name = "${local.name_prefix}-alb-${var.service_a_name}" }
}

# Blue target group (active)
resource "aws_lb_target_group" "service_a_blue" {
  name        = "${local.name_prefix}-tg-a-blue"
  port        = var.service_a_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  tags = { Name = "${local.name_prefix}-tg-${var.service_a_name}-blue" }
}

# Green target group (for Blue/Green CodeDeploy)
resource "aws_lb_target_group" "service_a_green" {
  name        = "${local.name_prefix}-tg-a-green"
  port        = var.service_a_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  tags = { Name = "${local.name_prefix}-tg-${var.service_a_name}-green" }
}

# HTTP listener → forward (or redirect to HTTPS when cert provided)
resource "aws_lb_listener" "service_a_http" {
  load_balancer_arn = aws_lb.service_a.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = local.enable_https ? "redirect" : "forward"

    dynamic "redirect" {
      for_each = local.enable_https ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    dynamic "forward" {
      for_each = local.enable_https ? [] : [1]
      content {
        target_group {
          arn    = aws_lb_target_group.service_a_blue.arn
          weight = 100
        }
      }
    }
  }
}

# HTTPS listener (only created when ACM cert ARN is provided)
resource "aws_lb_listener" "service_a_https" {
  count             = local.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.service_a.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service_a_blue.arn
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# SERVICE B – ALB (Order Service)
# ──────────────────────────────────────────────────────────────────────────────
resource "aws_lb" "service_b" {
  name               = "${local.name_prefix}-alb-svc-b"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = { Name = "${local.name_prefix}-alb-${var.service_b_name}" }
}

resource "aws_lb_target_group" "service_b_blue" {
  name        = "${local.name_prefix}-tg-b-blue"
  port        = var.service_b_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  tags = { Name = "${local.name_prefix}-tg-${var.service_b_name}-blue" }
}

resource "aws_lb_target_group" "service_b_green" {
  name        = "${local.name_prefix}-tg-b-green"
  port        = var.service_b_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  tags = { Name = "${local.name_prefix}-tg-${var.service_b_name}-green" }
}

resource "aws_lb_listener" "service_b_http" {
  load_balancer_arn = aws_lb.service_b.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = local.enable_https ? "redirect" : "forward"

    dynamic "redirect" {
      for_each = local.enable_https ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    dynamic "forward" {
      for_each = local.enable_https ? [] : [1]
      content {
        target_group {
          arn    = aws_lb_target_group.service_b_blue.arn
          weight = 100
        }
      }
    }
  }
}

resource "aws_lb_listener" "service_b_https" {
  count             = local.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.service_b.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service_b_blue.arn
  }
}
