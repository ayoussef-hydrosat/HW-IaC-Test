run "lambda_runtime_and_role" {
  command = plan

  variables {
    enable_cert_validation_records = false
    enable_k8s_resources           = false
  }


  assert {
    condition     = aws_lambda_function.cognito_custom_message_lambda.runtime == "nodejs20.x"
    error_message = "Lambda runtime must be nodejs20.x"
  }
}
