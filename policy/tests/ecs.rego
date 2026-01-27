package terraform

# Policy
# Require ECR repositories to enable scan on push and encryption.
deny contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_ecr_repository"
  after := rc.change.after
  after != null
  not after.image_scanning_configuration.scan_on_push
  msg := sprintf("ECR scan-on-push must be enabled: %s", [rc.address])
}

deny contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_ecr_repository"
  after := rc.change.after
  after != null
  after.encryption_configuration.encryption_type == ""
  msg := sprintf("ECR encryption must be enabled: %s", [rc.address])
}

autoscaling_minmax_invalid(after) if {
  to_number(after.min_capacity) > to_number(after.max_capacity)
}

# Tests

test_ecr_scan_on_push_required if {
  msg := deny[_] with input as input_ecr_no_scan
  msg == "ECR scan-on-push must be enabled: aws_ecr_repository.api"
}

test_ecr_encryption_required if {
  msg := deny[_] with input as input_ecr_no_encryption
  msg == "ECR encryption must be enabled: aws_ecr_repository.api"
}

# Fixtures

input_ecr_no_scan := {
  "resource_changes": [
    {
      "type": "aws_ecr_repository",
      "address": "aws_ecr_repository.api",
      "change": {
        "after": {
          "image_scanning_configuration": { "scan_on_push": false },
          "encryption_configuration": { "encryption_type": "AES256" }
        }
      }
    }
  ]
}

input_ecr_no_encryption := {
  "resource_changes": [
    {
      "type": "aws_ecr_repository",
      "address": "aws_ecr_repository.api",
      "change": {
        "after": {
          "image_scanning_configuration": { "scan_on_push": true },
          "encryption_configuration": { "encryption_type": "" }
        }
      }
    }
  ]
}
