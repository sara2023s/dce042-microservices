################################################################################
# ECR Module
# Creates two private ECR repositories – one per microservice.
# Both repos use AES-256 encryption and image scanning on push.
################################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ── Repository: Service A (Product Service) ───────────────────────────────────
resource "aws_ecr_repository" "service_a" {
  name                 = "${local.name_prefix}-${var.service_a_name}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = { Name = "${local.name_prefix}-${var.service_a_name}" }
}

# ── Repository: Service B (Order Service) ─────────────────────────────────────
resource "aws_ecr_repository" "service_b" {
  name                 = "${local.name_prefix}-${var.service_b_name}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = { Name = "${local.name_prefix}-${var.service_b_name}" }
}

# ── Lifecycle Policy: keep only the 10 most-recent tagged images ──────────────
resource "aws_ecr_lifecycle_policy" "service_a" {
  repository = aws_ecr_repository.service_a.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 tagged images"
        selection = {
          tagStatus   = "tagged"
          tagPrefixList = ["v"]
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = { type = "expire" }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "service_b" {
  repository = aws_ecr_repository.service_b.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = { type = "expire" }
      }
    ]
  })
}
