package terraform
import rego.v1

# Policy
# Deny IAM policies with wildcard actions.
deny contains msg if {
  rc := input.resource_changes[_]
  is_iam_policy_resource(rc.type)
  after := rc.change.after
  after != null
  policy := json.unmarshal(after.policy)
  statement := policy.Statement[_]
  has_wildcard_action(statement)
  msg := sprintf("IAM policy uses wildcard action: %s", [rc.address])
}

# Deny IAM policies with wildcard resources.
deny contains msg if {
  rc := input.resource_changes[_]
  is_iam_policy_resource(rc.type)
  after := rc.change.after
  after != null
  policy := json.unmarshal(after.policy)
  statement := policy.Statement[_]
  has_wildcard_resource(statement)
  msg := sprintf("IAM policy uses wildcard resource: %s", [rc.address])
}

is_iam_policy_resource(t) if { t == "aws_iam_policy" }
is_iam_policy_resource(t) if { t == "aws_iam_role_policy" }
is_iam_policy_resource(t) if { t == "aws_iam_user_policy" }

has_wildcard_action(statement) if {
  statement.Action == "*"
}

has_wildcard_action(statement) if {
  action := statement.Action[_]
  action == "*"
}

has_wildcard_resource(statement) if {
  statement.Resource == "*"
}

has_wildcard_resource(statement) if {
  resource := statement.Resource[_]
  resource == "*"
}

# Require GitHub OIDC roles to scope the subject condition.
deny contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_iam_role"
  after := rc.change.after
  after != null
  policy := json.unmarshal(after.assume_role_policy)
  statement := policy.Statement[_]
  is_github_oidc_principal(statement)
  not has_github_sub_condition(statement)
  msg := sprintf("GitHub OIDC role must scope subject: %s", [rc.address])
}

is_github_oidc_principal(statement) if {
  federated := statement.Principal.Federated
  endswith(federated, "token.actions.githubusercontent.com")
}

is_github_oidc_principal(statement) if {
  federated := statement.Principal.Federated[_]
  endswith(federated, "token.actions.githubusercontent.com")
}

has_github_sub_condition(statement) if {
  cond := statement.Condition
  cond.StringLike["token.actions.githubusercontent.com:sub"] != ""
}

has_github_sub_condition(statement) if {
  cond := statement.Condition
  cond.StringEquals["token.actions.githubusercontent.com:sub"] != ""
}

# Require role policy attachments to specify a policy ARN.
deny contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_iam_role_policy_attachment"
  after := rc.change.after
  after != null
  after.policy_arn == ""
  msg := sprintf("IAM role policy attachment must set policy_arn: %s", [rc.address])
}

# Tests

test_iam_wildcard_action_denied if {
  msg := deny[_] with input as input_wildcard_action
  msg == "IAM policy uses wildcard action: aws_iam_policy.wild_action"
}

test_iam_wildcard_resource_denied if {
  msg := deny[_] with input as input_wildcard_resource
  msg == "IAM policy uses wildcard resource: aws_iam_policy.wild_resource"
}

test_github_oidc_requires_sub if {
  msg := deny[_] with input as input_github_oidc_missing_sub
  msg == "GitHub OIDC role must scope subject: aws_iam_role.github"
}

test_role_policy_attachment_requires_arn if {
  msg := deny[_] with input as input_role_attachment_no_arn
  msg == "IAM role policy attachment must set policy_arn: aws_iam_role_policy_attachment.attach"
}

# Fixtures

input_wildcard_action := {
  "resource_changes": [
    {
      "type": "aws_iam_policy",
      "address": "aws_iam_policy.wild_action",
      "change": {
        "after": {
          "policy": "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"*\",\"Resource\":\"arn:aws:s3:::bucket\"}]}"
        }
      }
    }
  ]
}

input_wildcard_resource := {
  "resource_changes": [
    {
      "type": "aws_iam_policy",
      "address": "aws_iam_policy.wild_resource",
      "change": {
        "after": {
          "policy": "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"s3:GetObject\"],\"Resource\":\"*\"}]}"
        }
      }
    }
  ]
}

input_github_oidc_missing_sub := {
  "resource_changes": [
    {
      "type": "aws_iam_role",
      "address": "aws_iam_role.github",
      "change": {
        "after": {
          "assume_role_policy": "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Federated\":\"arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com\"},\"Action\":\"sts:AssumeRoleWithWebIdentity\"}]}"
        }
      }
    }
  ]
}

input_role_attachment_no_arn := {
  "resource_changes": [
    {
      "type": "aws_iam_role_policy_attachment",
      "address": "aws_iam_role_policy_attachment.attach",
      "change": { "after": { "policy_arn": "" } }
    }
  ]
}
