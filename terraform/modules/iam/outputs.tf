output "ecs_task_execution_role_arn" { value = aws_iam_role.ecs_task_execution.arn }
output "service_a_task_role_arn"     { value = aws_iam_role.service_a_task.arn }
output "service_b_task_role_arn"     { value = aws_iam_role.service_b_task.arn }
output "codebuild_role_arn"          { value = aws_iam_role.codebuild.arn }
output "codedeploy_role_arn"         { value = aws_iam_role.codedeploy.arn }
output "codepipeline_role_arn"       { value = aws_iam_role.codepipeline.arn }
