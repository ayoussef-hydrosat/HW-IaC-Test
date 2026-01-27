run "cognito_password_policy" {
  command = plan

  variables {
    enable_cert_validation_records = false
    enable_k8s_resources           = false
  }


  assert {
    condition     = aws_cognito_user_pool.main.password_policy[0].minimum_length >= 8
    error_message = "Cognito password min length must be >= 8"
  }

  assert {
    condition     = aws_cognito_user_pool.main.password_policy[0].require_lowercase
    error_message = "Cognito must require lowercase"
  }

  assert {
    condition     = aws_cognito_user_pool.main.password_policy[0].require_uppercase
    error_message = "Cognito must require uppercase"
  }

  assert {
    condition     = aws_cognito_user_pool.main.password_policy[0].require_numbers
    error_message = "Cognito must require numbers"
  }

  assert {
    condition     = aws_cognito_user_pool.main.password_policy[0].require_symbols
    error_message = "Cognito must require symbols"
  }
}

run "cognito_mfa_and_oauth" {
  command = plan

  variables {
    enable_cert_validation_records = false
    enable_k8s_resources           = false
  }


  assert {
    condition     = aws_cognito_user_pool.main.mfa_configuration != "OFF"
    error_message = "Cognito MFA must not be OFF"
  }

  assert {
    condition     = aws_cognito_user_pool_domain.main.domain != ""
    error_message = "Cognito main domain must be set"
  }

  assert {
    condition     = aws_cognito_user_pool_domain.backoffice.domain != ""
    error_message = "Cognito backoffice domain must be set"
  }

  assert {
    condition     = !contains(aws_cognito_user_pool_client.client.allowed_oauth_flows, "implicit")
    error_message = "Cognito client must not allow implicit flow"
  }
}
