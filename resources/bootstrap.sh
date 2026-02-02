#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT=${1:-${ENV:-}}

if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: $0 <staging|production> (or set ENV)" >&2
  exit 1
fi

case "$ENVIRONMENT" in
  staging)
    BUCKET="hywater-portal-staging-terraform-state"
    TABLE="hywater-portal-staging-terraform-state-lock"
    ;;
  production)
    BUCKET="hywater-portal-production-terraform-state"
    TABLE="hywater-portal-production-terraform-state-lock"
    ;;
  *)
    echo "ENV must be staging or production" >&2
    exit 1
    ;;
esac

REGION="us-west-2"

# Create S3 bucket
aws s3api create-bucket \
  --bucket "$BUCKET" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"

# Enable versioning on the bucket
aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

# Create DynamoDB table
aws dynamodb create-table \
  --table-name "$TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION"
