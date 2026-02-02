
resource "aws_ses_email_identity" "sender_email" {
  email = "no-reply@${local.domain_name}"
}

resource "aws_ses_domain_identity" "portal_domain" {
  domain = local.domain_name
}

resource "aws_ses_domain_identity" "hydrosat_domain" {
  domain = "hydrosat.com"
}

resource "aws_ses_identity_policy" "cognito_ses_identity_policy" {
  identity = "no-reply@${local.domain_name}"
  name     = "AllowCognitoSendEmail"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cognito-idp.amazonaws.com"
        },
        Action   = "SES:SendEmail",
        Resource = "arn:aws:ses:${local.region}:${local.account_id}:identity/no-reply@${local.domain_name}"
      }
    ]
  })
}

resource "aws_ses_configuration_set" "email_service_config_set" {
  name = "email-service-config-set"
}

# SES Receipt Rule Set - Useful to verify email addresses without inbox, for example no-reply
resource "aws_ses_receipt_rule_set" "default" {
  rule_set_name = "default-rule-set"
}

resource "aws_ses_receipt_rule" "ses_receiving_rule" {
  rule_set_name = aws_ses_receipt_rule_set.default.rule_set_name
  name          = "ses-receiving-s3"
  enabled       = true

  s3_action {
    bucket_name       = aws_s3_bucket.bucket_email_receipts.bucket
    object_key_prefix = "emails/"
    position          = 1
  }
}
