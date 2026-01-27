run "secrets_manager" {
  command = plan

  variables {
    enable_cert_validation_records = false
    enable_k8s_resources           = false
  }

  assert {
    condition     = aws_secretsmanager_secret.rds_password.name != ""
    error_message = "RDS secret must have a name"
  }

  assert {
    condition     = length(aws_secretsmanager_secret_version.rds_password.secret_string) > 0
    error_message = "RDS secret version must set a secret string"
  }

  assert {
    condition     = aws_secretsmanager_secret.grafana_cloud_alloy.name != ""
    error_message = "Grafana secret must have a name"
  }

  assert {
    condition     = length(aws_secretsmanager_secret_version.grafana_cloud_alloy.secret_string) > 0
    error_message = "Grafana secret version must set a secret string"
  }
}
