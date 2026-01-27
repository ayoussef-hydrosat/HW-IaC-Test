resource "aws_cognito_user_pool" "main" {
  name = "${local.project_name}-user-pool"

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  username_attributes = ["email"]

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  email_configuration {
    email_sending_account = "DEVELOPER"
    from_email_address    = "no-reply@${local.domain_name}"
    source_arn            = "arn:aws:ses:${local.region}:${local.account_id}:identity/no-reply@${local.domain_name}"
    configuration_set     = aws_ses_configuration_set.email_service_config_set.name
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "Your verification code"
    email_message        = "Your verification code is {####}"
  }

  mfa_configuration = "OPTIONAL"

  software_token_mfa_configuration {
    enabled = true
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  lambda_config {
    custom_message = "arn:aws:lambda:${local.region}:${local.account_id}:function:cognito-custom-message-lambda-${local.environment}"
  }
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${local.project_name}-auth"
  user_pool_id = aws_cognito_user_pool.main.id
}

resource "aws_cognito_user_pool_client" "client" {
  name         = "${local.project_name}-client"
  user_pool_id = aws_cognito_user_pool.main.id

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30

  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true

  callback_urls = ["http://localhost:3000", "https://${local.domain_name}"]
  logout_urls   = ["http://localhost:3000", "https://${local.domain_name}"]

  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["email", "openid", "profile"]

  supported_identity_providers = ["COGNITO"]
}

resource "aws_cognito_user_pool" "backoffice" {
  name = "${local.project_name}-backoffice-user-pool"

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  username_attributes = ["email"]

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  email_configuration {
    email_sending_account = "DEVELOPER"
    from_email_address    = "no-reply@${local.domain_name}"
    source_arn            = "arn:aws:ses:${local.region}:${local.account_id}:identity/no-reply@${local.domain_name}"
    configuration_set     = aws_ses_configuration_set.email_service_config_set.name
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "Your verification code"
    email_message        = "Your verification code is {####}"
  }

  mfa_configuration = "OPTIONAL"

  software_token_mfa_configuration {
    enabled = true
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  lambda_config {
    custom_message = "arn:aws:lambda:${local.region}:${local.account_id}:function:cognito-custom-message-lambda-${local.environment}"
  }
}

resource "aws_cognito_user_pool_domain" "backoffice" {
  domain       = "${local.project_name}-backoffice-auth"
  user_pool_id = aws_cognito_user_pool.backoffice.id
}

resource "aws_cognito_user_pool_client" "backoffice_client" {
  name         = "${local.project_name}-backoffice-client"
  user_pool_id = aws_cognito_user_pool.backoffice.id

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30

  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true

  callback_urls = ["http://localhost:3000", "https://admin.${local.domain_name}"]
  logout_urls   = ["http://localhost:3000", "https://admin.${local.domain_name}"]

  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["email", "openid", "profile"]

  supported_identity_providers = ["COGNITO"]
}
