package terraform
import rego.v1

# Policy
# Require bucket policies to be defined.
deny contains msg if {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket_policy"
  after := resource.change.after
  after != null
  after.policy == ""
  msg := sprintf("S3 bucket policy must be set: %s", [resource.address])
}

# Tests

test_s3_bucket_policy_required if {
  msg := deny[_] with input as input_bucket_policy_missing
  msg == "S3 bucket policy must be set: aws_s3_bucket_policy.frontend"
}

# Fixtures

input_bucket_policy_missing := {
  "resource_changes": [
    {
      "type": "aws_s3_bucket_policy",
      "address": "aws_s3_bucket_policy.frontend",
      "change": { "after": { "policy": "" } }
    }
  ]
}
