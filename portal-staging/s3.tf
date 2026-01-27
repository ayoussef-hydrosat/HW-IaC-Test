resource "aws_s3_bucket" "bucket_lambdas" {
  bucket = "${local.project_name}-lambdas"
}

resource "aws_s3_bucket_versioning" "bucket_lambdas_versioning" {
  bucket = aws_s3_bucket.bucket_lambdas.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "bucket_email_receipts" {
  bucket = "${local.project_name}-email-receipts"
}

resource "aws_s3_bucket_policy" "bucket_email_receipts_policy" {
  bucket = aws_s3_bucket.bucket_email_receipts.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ses.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.bucket_email_receipts.arn}/*"
        Condition = {
          StringEquals = { "aws:Referer" = local.account_id }
        }
      }
    ]
  })
}
