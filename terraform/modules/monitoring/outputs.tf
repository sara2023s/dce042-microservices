output "service_a_scale_out_policy_arn" { value = aws_appautoscaling_policy.service_a_scale_out.arn }
output "service_a_scale_in_policy_arn"  { value = aws_appautoscaling_policy.service_a_scale_in.arn }
output "service_b_scale_out_policy_arn" { value = aws_appautoscaling_policy.service_b_scale_out.arn }
output "service_b_scale_in_policy_arn"  { value = aws_appautoscaling_policy.service_b_scale_in.arn }
output "dashboard_name"                 { value = aws_cloudwatch_dashboard.main.dashboard_name }
