output "artifacts_bucket_id"  { value = aws_s3_bucket.artifacts.id }
output "artifacts_bucket_arn" { value = aws_s3_bucket.artifacts.arn }
output "assets_bucket_name"   { value = aws_s3_bucket.assets.id }
output "assets_bucket_arn"    { value = aws_s3_bucket.assets.arn }
output "dynamodb_table_name"  { value = aws_dynamodb_table.app_data.name }
output "dynamodb_table_arn"   { value = aws_dynamodb_table.app_data.arn }
output "sns_topic_arn"        { value = aws_sns_topic.notifications.arn }
