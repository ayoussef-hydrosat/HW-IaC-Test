package terraform
import rego.v1

# Policy
# Require Cognito invoke permissions for Lambda.
deny contains msg if {
  resource := input.resource_changes[_]
  resource.type == "aws_lambda_permission"
  after := resource.change.after
  after != null
  after.principal != "cognito-idp.amazonaws.com"
  msg := sprintf("Lambda permission principal must be cognito-idp.amazonaws.com: %s", [resource.address])
}

deny contains msg if {
  resource := input.resource_changes[_]
  resource.type == "aws_lambda_permission"
  after := resource.change.after
  after != null
  after.action != "lambda:InvokeFunction"
  msg := sprintf("Lambda permission action must be lambda:InvokeFunction: %s", [resource.address])
}

# Tests

test_lambda_permission_principal if {
  msg := deny[_] with input as input_permission_bad_principal
  msg == "Lambda permission principal must be cognito-idp.amazonaws.com: aws_lambda_permission.bad"
}

test_lambda_permission_action if {
  msg := deny[_] with input as input_permission_bad_action
  msg == "Lambda permission action must be lambda:InvokeFunction: aws_lambda_permission.bad_action"
}

# Fixtures

input_permission_bad_principal := {
  "resource_changes": [
    {
      "type": "aws_lambda_permission",
      "address": "aws_lambda_permission.bad",
      "change": { "after": { "principal": "apigateway.amazonaws.com", "action": "lambda:InvokeFunction" } }
    }
  ]
}

input_permission_bad_action := {
  "resource_changes": [
    {
      "type": "aws_lambda_permission",
      "address": "aws_lambda_permission.bad_action",
      "change": { "after": { "principal": "cognito-idp.amazonaws.com", "action": "lambda:InvokeFunctionUrl" } }
    }
  ]
}
