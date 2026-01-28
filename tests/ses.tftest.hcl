run "ses_basics" {
  command = plan

  variables {
    is_test_mode_enabled = true
  }

  assert {
    condition     = aws_ses_email_identity.sender_email.email != ""
    error_message = "SES sender email identity must be set"
  }

  assert {
    condition     = aws_ses_domain_identity.portal_domain.domain != ""
    error_message = "SES portal domain identity must be set"
  }

  assert {
    condition     = aws_ses_configuration_set.email_service_config_set.name != ""
    error_message = "SES configuration set name must be set"
  }

  assert {
    condition     = aws_ses_receipt_rule_set.default.rule_set_name != ""
    error_message = "SES receipt rule set must be named"
  }

  assert {
    condition     = aws_ses_receipt_rule.ses_receiving_rule.enabled
    error_message = "SES receipt rule must be enabled"
  }
}
