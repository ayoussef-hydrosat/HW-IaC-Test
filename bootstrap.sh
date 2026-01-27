ENV="${ENV:-staging}"
STATE_BUCKET="hywater-portal-${ENV}-terraform-state"
STATE_LOCK_TABLE="hywater-portal-${ENV}-terraform-state-lock"

# Create S3 bucket
aws s3api create-bucket \
    --bucket "${STATE_BUCKET}" \
    --region us-west-2 \
    --create-bucket-configuration LocationConstraint=us-west-2

# Enable versioning on the bucket
aws s3api put-bucket-versioning \
    --bucket "${STATE_BUCKET}" \
    --versioning-configuration Status=Enabled

# Create DynamoDB table
aws dynamodb create-table \
    --table-name "${STATE_LOCK_TABLE}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region us-west-2 \
