data "aws_s3_object" "cognito_custom_message" {
  bucket = aws_s3_bucket.bucket_lambdas.bucket
  key    = "cognitoCustomMessage.zip"
}

resource "aws_lambda_function" "cognito_custom_message_lambda" {
  function_name     = "cognito-custom-message-lambda-${local.environment}"
  runtime           = "nodejs20.x"
  role              = aws_iam_role.cognito_custom_message_lambda_role.arn
  handler           = "index.handler"
  s3_bucket         = aws_s3_bucket.bucket_lambdas.bucket
  s3_key            = data.aws_s3_object.cognito_custom_message.key
  s3_object_version = data.aws_s3_object.cognito_custom_message.version_id

  environment {
    variables = {
      PORTAL_CALLBACK_URL     = "https://${local.domain_name}"
      BACKOFFICE_CALLBACK_URL = "https://admin.${local.domain_name}"
      PORTAL_USER_POOL_ID     = aws_cognito_user_pool.main.id
      BACKOFFICE_USER_POOL_ID = aws_cognito_user_pool.backoffice.id
    }
  }

  timeout     = 30
  memory_size = 128
}

resource "aws_lambda_permission" "cognito_custom_message_permission_main" {
  statement_id  = "AllowCognitoInvokeCustomMessage"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cognito_custom_message_lambda.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.main.arn
}

resource "aws_lambda_permission" "cognito_custom_message_permission_backoffice" {
  statement_id  = "AllowCognitoInvokeCustomMessageBackoffice"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cognito_custom_message_lambda.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.backoffice.arn
}
