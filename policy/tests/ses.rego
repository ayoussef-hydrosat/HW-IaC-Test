package terraform

# Policy
# Require SES identity policies to be defined.
deny contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_ses_identity_policy"
  after := rc.change.after
  after != null
  after.policy == ""
  msg := sprintf("SES identity policy must be set: %s", [rc.address])
}

# Tests

test_ses_identity_policy_required if {
  msg := deny[_] with input as input_identity_policy_missing
  msg == "SES identity policy must be set: aws_ses_identity_policy.cognito"
}

# Fixtures

input_identity_policy_missing := {
  "resource_changes": [
    {
      "type": "aws_ses_identity_policy",
      "address": "aws_ses_identity_policy.cognito",
      "change": { "after": { "policy": "" } }
    }
  ]
}
