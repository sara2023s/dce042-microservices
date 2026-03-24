variable "project_name"          { type = string }
variable "environment"            { type = string }
variable "aws_region"             { type = string }
variable "artifacts_bucket_arn"   { type = string }
variable "assets_bucket_arn"      { type = string }
variable "ecr_repo_arns"          { type = list(string) }
