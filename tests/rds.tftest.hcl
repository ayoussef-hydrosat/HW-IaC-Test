run "rds_security" {
  command = plan

  variables {
    is_test_mode_enabled = true
  }


  assert {
    condition     = aws_db_instance.postgresql.storage_encrypted == true
    error_message = "RDS storage must be encrypted"
  }

  assert {
    condition     = aws_db_instance.postgresql.backup_retention_period >= 7
    error_message = "RDS backup retention must be >= 7 days"
  }

  assert {
    condition     = try(aws_db_instance.postgresql.publicly_accessible, false) == false
    error_message = "RDS must not be publicly accessible"
  }

  assert {
    condition     = aws_db_subnet_group.postgresql.name != ""
    error_message = "RDS subnet group must be set"
  }

  assert {
    condition     = aws_db_parameter_group.postgresql.family == "postgres17"
    error_message = "RDS parameter group family must be postgres17"
  }
}

run "bastion_requirements" {
  command = plan

  variables {
    is_test_mode_enabled = true
  }


  assert {
    condition     = aws_instance.bastion.key_name != ""
    error_message = "Bastion must have an SSH key"
  }

  assert {
    condition     = aws_security_group.bastion.name != ""
    error_message = "Bastion security group must exist"
  }
}
