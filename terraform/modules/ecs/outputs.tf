output "cluster_name"    { value = aws_ecs_cluster.main.name }
output "cluster_arn"     { value = aws_ecs_cluster.main.arn }
output "service_a_name"  { value = aws_ecs_service.service_a.name }
output "service_b_name"  { value = aws_ecs_service.service_b.name }
output "task_def_a_arn"  { value = aws_ecs_task_definition.service_a.arn }
output "task_def_b_arn"  { value = aws_ecs_task_definition.service_b.arn }
output "log_group_a"     { value = aws_cloudwatch_log_group.service_a.name }
output "log_group_b"     { value = aws_cloudwatch_log_group.service_b.name }
