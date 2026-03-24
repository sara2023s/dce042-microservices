################################################################################
# Root Variables
# DCE 04.2 – Assessment 1: Multi-Cloud Automation and Emerging Technologies
################################################################################

variable "aws_region" {
  description = "AWS region to deploy all resources into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Unique project prefix used to name every resource"
  type        = string
  default     = "dce042"
}

variable "environment" {
  description = "Deployment environment (dev / staging / prod)"
  type        = string
  default     = "dev"
}

# ── Networking ────────────────────────────────────────────────────────────────
variable "vpc_cidr" {
  description = "CIDR block for the dedicated VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the two public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the two private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "availability_zones" {
  description = "List of two AZs for high-availability"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# ── ECS / Container ───────────────────────────────────────────────────────────
variable "service_a_name" {
  description = "Name for microservice A (Product Service)"
  type        = string
  default     = "product-service"
}

variable "service_b_name" {
  description = "Name for microservice B (Order Service)"
  type        = string
  default     = "order-service"
}

variable "service_a_cpu" {
  description = "Fargate CPU units for service A (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "service_a_memory" {
  description = "Fargate memory (MB) for service A"
  type        = number
  default     = 512
}

variable "service_b_cpu" {
  description = "Fargate CPU units for service B"
  type        = number
  default     = 256
}

variable "service_b_memory" {
  description = "Fargate memory (MB) for service B"
  type        = number
  default     = 512
}

variable "service_a_desired_count" {
  description = "Desired running task count for service A"
  type        = number
  default     = 2
}

variable "service_b_desired_count" {
  description = "Desired running task count for service B"
  type        = number
  default     = 2
}

variable "service_a_container_port" {
  description = "Container port exposed by service A"
  type        = number
  default     = 5000
}

variable "service_b_container_port" {
  description = "Container port exposed by service B"
  type        = number
  default     = 5001
}

# ── Autoscaling ───────────────────────────────────────────────────────────────
variable "autoscaling_min_capacity" {
  description = "Minimum ECS task count per service"
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum ECS task count per service"
  type        = number
  default     = 4
}

variable "cpu_scale_out_threshold" {
  description = "CPU % above which a scale-out alarm fires"
  type        = number
  default     = 70
}

variable "cpu_scale_in_threshold" {
  description = "CPU % below which a scale-in alarm fires"
  type        = number
  default     = 30
}

# ── CI/CD ─────────────────────────────────────────────────────────────────────
variable "github_owner" {
  description = "GitHub account / organisation that owns the source repository"
  type        = string
  default     = "your-github-username"
}

variable "github_repo" {
  description = "GitHub repository name containing both microservices"
  type        = string
  default     = "dce042-microservices"
}

variable "github_branch" {
  description = "Branch to trigger CI/CD pipeline from"
  type        = string
  default     = "main"
}

variable "codestar_connection_arn" {
  description = "ARN of an existing CodeStar (GitHub) connection"
  type        = string
  default     = ""  # Set this after creating the connection in the AWS Console
}

# ── ALB / HTTPS ───────────────────────────────────────────────────────────────
variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS listeners (leave empty to skip HTTPS)"
  type        = string
  default     = ""
}

# ── Notifications ─────────────────────────────────────────────────────────────
variable "alert_email" {
  description = "Email address to receive CloudWatch / SNS notifications"
  type        = string
  default     = "devops@example.com"
}

# ── Azure Entra ID Federation ─────────────────────────────────────────────────
variable "entra_saml_metadata_url" {
  description = "App Federation Metadata URL from the Entra ID Enterprise Application"
  type        = string
  default     = ""
}

variable "entra_saml_metadata_xml" {
  description = "Raw SAML metadata XML (used when the URL is not publicly reachable)"
  type        = string
  default     = ""
}

# ── Remote State Backend (pre-created via scripts/setup-backend.sh) ───────────
variable "tf_state_bucket" {
  description = "S3 bucket name that stores the Terraform remote state"
  type        = string
  default     = "dce042-tf-state"
}

variable "tf_state_lock_table" {
  description = "DynamoDB table name used for Terraform state locking"
  type        = string
  default     = "dce042-tf-state-lock"
}
