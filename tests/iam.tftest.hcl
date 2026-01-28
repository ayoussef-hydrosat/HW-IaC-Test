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
