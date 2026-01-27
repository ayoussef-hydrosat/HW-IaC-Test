# Create S3 bucket
aws s3api create-bucket \
    --bucket hywater-portal-staging-terraform-state \
    --region us-west-2 \
    --create-bucket-configuration LocationConstraint=us-west-2

# Enable versioning on the bucket
aws s3api put-bucket-versioning \
    --bucket hywater-portal-staging-terraform-state \
    --versioning-configuration Status=Enabled

# Create DynamoDB table
aws dynamodb create-table \
    --table-name hywater-portal-staging-terraform-state-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region us-west-2 \
