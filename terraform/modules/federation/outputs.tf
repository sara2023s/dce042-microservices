output "saml_provider_arn" {
  value = length(aws_iam_saml_provider.entra_id) > 0 ? aws_iam_saml_provider.entra_id[0].arn : "not-configured"
}
output "devops_engineer_role_arn"  { value = aws_iam_role.devops_engineer.arn }
output "readonly_auditor_role_arn" { value = aws_iam_role.readonly_auditor.arn }
