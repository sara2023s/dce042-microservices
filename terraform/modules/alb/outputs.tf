output "service_a_alb_dns"      { value = aws_lb.service_a.dns_name }
output "service_b_alb_dns"      { value = aws_lb.service_b.dns_name }
output "service_a_tg_arn"       { value = aws_lb_target_group.service_a_blue.arn }
output "service_b_tg_arn"       { value = aws_lb_target_group.service_b_blue.arn }
output "service_a_tg_green_arn" { value = aws_lb_target_group.service_a_green.arn }
output "service_b_tg_green_arn" { value = aws_lb_target_group.service_b_green.arn }
output "service_a_listener_arn" {
  value = local.enable_https ? aws_lb_listener.service_a_https[0].arn : aws_lb_listener.service_a_http.arn
}
output "service_b_listener_arn" {
  value = local.enable_https ? aws_lb_listener.service_b_https[0].arn : aws_lb_listener.service_b_http.arn
}
output "service_a_alb_arn"      { value = aws_lb.service_a.arn }
output "service_b_alb_arn"      { value = aws_lb.service_b.arn }
