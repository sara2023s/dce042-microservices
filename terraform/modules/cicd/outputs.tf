output "codepipeline_name"        { value = length(aws_codepipeline.main) > 0 ? aws_codepipeline.main[0].name : "not-yet-created" }
output "codebuild_service_a_name" { value = aws_codebuild_project.service_a.name }
output "codebuild_service_b_name" { value = aws_codebuild_project.service_b.name }
output "codedeploy_app_a_name"    { value = aws_codedeploy_app.service_a.name }
output "codedeploy_app_b_name"    { value = aws_codedeploy_app.service_b.name }
