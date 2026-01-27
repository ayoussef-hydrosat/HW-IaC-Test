# AWS Secrets Manager secret for RDS password
resource "aws_secretsmanager_secret" "rds_password" {
  name = "${local.project_name}/rds/password"

  tags = {
    Name        = "${local.project_name}-rds-password"
    Environment = local.environment
    Project     = local.project_name
  }
}

# Store the initial password in Secrets Manager
resource "aws_secretsmanager_secret_version" "rds_password" {
  secret_id = aws_secretsmanager_secret.rds_password.id
  secret_string = jsonencode({
    username = local.db_username
    password = var.db_password
  })
}

# IAM policy for ECS tasks to read the secret
resource "aws_iam_policy" "ecs_task_secrets" {
  name        = "${local.project_name}-ecs-secrets-policy"
  description = "Policy to allow ECS tasks to read RDS secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [aws_secretsmanager_secret.rds_password.arn]
      }
    ]
  })
}

# Attach the secrets policy to the ECS task role
resource "aws_iam_role_policy_attachment" "ecs_task_secrets" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.ecs_task_secrets.arn
}

# AWS Secrets Manager secret for Grafana Cloud Loki password for Alloy to access
resource "aws_secretsmanager_secret" "grafana_cloud_alloy" {
  name = "${local.project_name}/grafana-cloud/password"
}

resource "aws_secretsmanager_secret_version" "grafana_cloud_alloy" {
  secret_id = aws_secretsmanager_secret.grafana_cloud_alloy.id
  secret_string = jsonencode({
    password = var.grafana_cloud_password
  })
}