run "iam_github_oidc_sub_condition" {
  command = plan

  variables {
    is_test_mode_enabled = true
  }


  assert {
    condition     = aws_iam_openid_connect_provider.github.url == "https://token.actions.githubusercontent.com"
    error_message = "GitHub OIDC provider must use token.actions.githubusercontent.com"
  }

  assert {
    condition     = contains(aws_iam_openid_connect_provider.github.client_id_list, "sts.amazonaws.com")
    error_message = "GitHub OIDC provider must allow sts.amazonaws.com"
  }

  assert {
    condition     = aws_iam_user.cicd.name != ""
    error_message = "IAM cicd user must exist"
  }

  assert {
    condition     = aws_iam_access_key.cicd.user == aws_iam_user.cicd.name
    error_message = "IAM access key must belong to the cicd user"
  }

}

run "iam_github_actions_roles" {
  command = plan

  variables {
    is_test_mode_enabled = true
  }


  assert {
    condition     = endswith(aws_iam_role.github_actions_frontend_deployment.name, "-github-actions-frontend-deployment")
    error_message = "Frontend deployment role name must end with -github-actions-frontend-deployment"
  }

  assert {
    condition     = endswith(aws_iam_role.github_actions_backend_deployment.name, "-github-actions-backend-deployment")
    error_message = "Backend deployment role name must end with -github-actions-backend-deployment"
  }

  assert {
    condition     = endswith(aws_iam_role.github_actions_infra_plan.name, "-github-actions-infra-pr")
    error_message = "Infra plan role name must end with -github-actions-infra-pr"
  }

  assert {
    condition     = endswith(aws_iam_role.github_actions_backoffice_deployment.name, "-github-actions-backoffice-deployment")
    error_message = "Backoffice deployment role name must end with -github-actions-backoffice-deployment"
  }

  assert {
    condition     = endswith(aws_iam_role.github_actions_lambda_deployment.name, "-github-actions-lambda-deployment")
    error_message = "Lambda deployment role name must end with -github-actions-lambda-deployment"
  }

  assert {
    condition     = endswith(aws_iam_role.github_actions_infra_deployment.name, "-github-actions-infra-deployment")
    error_message = "Infra deployment role name must end with -github-actions-infra-deployment"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.github_actions_infra_deployment_admin.policy_arn != ""
    error_message = "Infra deployment role must attach a managed policy"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.github_actions_infra_deployment_admin.policy_arn == "arn:aws:iam::aws:policy/AdministratorAccess"
    error_message = "Infra deployment role must attach AdministratorAccess"
  }
}
