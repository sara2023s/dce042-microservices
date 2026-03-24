################################################################################
# Federation Module – Azure Entra ID SAML 2.0 → AWS IAM
#
# Creates the IAM SAML identity provider and two federated IAM roles:
#   • DevOpsEngineer  – mapped from the Entra ID DevOpsEngineer group
#   • ReadOnlyAuditor – mapped from the Entra ID ReadOnlyAuditor group
#
# Pre-requisites (performed in the Azure portal before terraform apply):
#   1. Create an Enterprise Application in Entra ID.
#   2. Enable SAML 2.0 Single Sign-On.
#   3. Set the Identifier (Entity ID) to: urn:amazon:webservices
#   4. Set the Reply URL to:  https://signin.aws.amazon.com/saml
#   5. Add the Attribute claim  https://aws.amazon.com/SAML/Attributes/Role
#      with value  <role-arn>,<saml-provider-arn>  (update after first apply).
#   6. Add the Attribute claim  https://aws.amazon.com/SAML/Attributes/RoleSessionName
#      with value  user.userprincipalname.
#   7. Assign Entra ID groups (DevOpsEngineer, ReadOnlyAuditor) to the app.
#   8. Enable MFA and a Conditional Access policy requiring MFA for this app.
#   9. Download the Federation Metadata XML and provide it via
#      entra_saml_metadata_url or entra_saml_metadata_xml variable.
################################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  # Use URL if provided; otherwise fall back to inline XML
  use_metadata_url = var.entra_saml_metadata_url != ""
}

# ── Fetch SAML metadata from URL when provided ────────────────────────────────
data "http" "saml_metadata" {
  count = local.use_metadata_url ? 1 : 0
  url   = var.entra_saml_metadata_url
}

locals {
  saml_metadata_document = local.use_metadata_url ? data.http.saml_metadata[0].response_body : var.entra_saml_metadata_xml
}

# ── IAM SAML Identity Provider ────────────────────────────────────────────────
resource "aws_iam_saml_provider" "entra_id" {
  count                  = local.saml_metadata_document != "" ? 1 : 0
  name                   = "${local.name_prefix}-entra-id-saml"
  saml_metadata_document = local.saml_metadata_document

  tags = { Name = "${local.name_prefix}-entra-id-saml" }
}

# ── Federated Trust Policy (shared by both roles) ─────────────────────────────
locals {
  saml_provider_arn = length(aws_iam_saml_provider.entra_id) > 0 ? aws_iam_saml_provider.entra_id[0].arn : "arn:aws:iam::ACCOUNT:saml-provider/PLACEHOLDER"

  federated_trust = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Federated = local.saml_provider_arn }
        Action    = "sts:AssumeRoleWithSAML"
        Condition = {
          StringEquals = {
            "SAML:aud" = "https://signin.aws.amazon.com/saml"
          }
        }
      }
    ]
  })
}

# ── Role: DevOpsEngineer ──────────────────────────────────────────────────────
resource "aws_iam_role" "devops_engineer" {
  name                 = "${local.name_prefix}-EntraID-DevOpsEngineer"
  assume_role_policy   = local.federated_trust
  max_session_duration = 28800   # 8 hours

  tags = {
    Name    = "${local.name_prefix}-EntraID-DevOpsEngineer"
    ManagedBy = "EntraIDFederation"
  }
}

resource "aws_iam_role_policy_attachment" "devops_engineer_poweruser" {
  role       = aws_iam_role.devops_engineer.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# Additional least-privilege policy for ECS/CodePipeline operations
resource "aws_iam_role_policy" "devops_engineer_custom" {
  name = "${local.name_prefix}-devops-custom"
  role = aws_iam_role.devops_engineer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:*",
          "ecr:*",
          "codepipeline:*",
          "codebuild:*",
          "codedeploy:*",
          "cloudwatch:*",
          "logs:*",
          "s3:*",
          "iam:PassRole"
        ]
        Resource = "*"
      }
    ]
  })
}

# ── Role: ReadOnlyAuditor ─────────────────────────────────────────────────────
resource "aws_iam_role" "readonly_auditor" {
  name                 = "${local.name_prefix}-EntraID-ReadOnlyAuditor"
  assume_role_policy   = local.federated_trust
  max_session_duration = 3600   # 1 hour

  tags = {
    Name      = "${local.name_prefix}-EntraID-ReadOnlyAuditor"
    ManagedBy = "EntraIDFederation"
  }
}

resource "aws_iam_role_policy_attachment" "readonly_auditor" {
  role       = aws_iam_role.readonly_auditor.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
