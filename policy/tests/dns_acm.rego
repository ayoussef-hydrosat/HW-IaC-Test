package terraform

# Policy
# Require ACM certificate validation records to be present when set.
deny contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_acm_certificate_validation"
  after := rc.change.after
  after != null
  after.validation_record_fqdns != null
  count(after.validation_record_fqdns) == 0
  msg := sprintf("ACM certificate validation must include DNS records: %s", [rc.address])
}

# Tests

test_acm_validation_records_required if {
  msg := deny[_] with input as input_acm_validation_no_records
  msg == "ACM certificate validation must include DNS records: aws_acm_certificate_validation.main"
}

# Fixtures

input_acm_validation_no_records := {
  "resource_changes": [
    {
      "type": "aws_acm_certificate_validation",
      "address": "aws_acm_certificate_validation.main",
      "change": { "after": { "validation_record_fqdns": [] } }
    }
  ]
}
