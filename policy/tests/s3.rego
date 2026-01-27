package terraform

# Policy
# Require bucket policies to be defined.
deny contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_s3_bucket_policy"
  after := rc.change.after
  after != null
  after.policy == ""
  msg := sprintf("S3 bucket policy must be set: %s", [rc.address])
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
