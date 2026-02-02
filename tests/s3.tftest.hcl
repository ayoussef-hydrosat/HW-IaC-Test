run "s3_public_access_block" {
  command = plan

  variables {
    is_test_mode_enabled = true
  }


  assert {
    condition     = aws_s3_bucket_public_access_block.frontend.block_public_acls
    error_message = "S3 frontend must block public ACLs"
  }
  assert {
    condition     = aws_s3_bucket_public_access_block.frontend.block_public_policy
    error_message = "S3 frontend must block public bucket policies"
  }
  assert {
    condition     = aws_s3_bucket_public_access_block.frontend.ignore_public_acls
    error_message = "S3 frontend must ignore public ACLs"
  }
  assert {
    condition     = aws_s3_bucket_public_access_block.frontend.restrict_public_buckets
    error_message = "S3 frontend must restrict public buckets"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.backoffice.block_public_acls
    error_message = "S3 backoffice must block public ACLs"
  }
  assert {
    condition     = aws_s3_bucket_public_access_block.backoffice.block_public_policy
    error_message = "S3 backoffice must block public bucket policies"
  }
  assert {
    condition     = aws_s3_bucket_public_access_block.backoffice.ignore_public_acls
    error_message = "S3 backoffice must ignore public ACLs"
  }
  assert {
    condition     = aws_s3_bucket_public_access_block.backoffice.restrict_public_buckets
    error_message = "S3 backoffice must restrict public buckets"
  }
}

run "s3_acl_and_encryption" {
  command = plan

  variables {
    is_test_mode_enabled = true
  }


  assert {
    condition     = endswith(aws_s3_bucket.frontend.bucket, "-frontend-bucket")
    error_message = "S3 frontend bucket name must end with -frontend-bucket"
  }
  assert {
    condition     = endswith(aws_s3_bucket.backoffice.bucket, "-backoffice-bucket")
    error_message = "S3 backoffice bucket name must end with -backoffice-bucket"
  }

  assert {
    condition     = aws_s3_bucket_website_configuration.frontend.index_document[0].suffix == "index.html"
    error_message = "S3 frontend website must set index.html"
  }

  assert {
    condition     = aws_s3_bucket_website_configuration.backoffice.index_document[0].suffix == "index.html"
    error_message = "S3 backoffice website must set index.html"
  }
}

run "s3_versioning_and_lambda_bucket" {
  command = plan

  variables {
    is_test_mode_enabled = true
  }


  assert {
    condition     = aws_s3_bucket_versioning.bucket_lambdas_versioning.versioning_configuration[0].status == "Enabled"
    error_message = "Lambda bucket versioning must be enabled"
  }

  assert {
    condition     = endswith(aws_s3_bucket.bucket_lambdas.bucket, "-lambdas")
    error_message = "Lambda bucket must end with -lambdas"
  }
}
