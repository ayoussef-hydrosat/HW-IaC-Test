resource "aws_iam_user" "cicd" {
  name = "${local.project_name}-cicd"
}

resource "aws_iam_access_key" "cicd" {
  user = aws_iam_user.cicd.name
}

data "aws_iam_policy_document" "cicd" {
  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:GetAuthorizationToken"
    ]
    resources = [aws_ecr_repository.api.arn]
  }

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "iam:ListAttachedUserPolicies",
      "sts:AssumeRole",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchCheckLayerAvailability",
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      aws_secretsmanager_secret.rds_password.arn
    ]
    effect = "Allow"
  }

  statement {
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices",
      "ecs:DescribeClusters"
    ]
    resources = [
      aws_ecs_cluster.main.arn,
      aws_ecs_service.api.id
    ]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [
      aws_s3_bucket.frontend.arn,
      "${aws_s3_bucket.frontend.arn}/*",
      aws_s3_bucket.backoffice.arn,
      "${aws_s3_bucket.backoffice.arn}/*"
    ]
    effect = "Allow"
  }

  statement {
    actions = [
      "cloudfront:CreateInvalidation",
      "cloudfront:GetInvalidation",
      "cloudfront:ListInvalidations"
    ]
    resources = [aws_cloudfront_distribution.frontend.arn, aws_cloudfront_distribution.backoffice.arn]
    effect    = "Allow"
  }

  depends_on = [aws_cloudfront_distribution.frontend, aws_cloudfront_distribution.backoffice]
}

resource "aws_iam_role" "cicd_cross_account_role" {
  name = "${local.project_name}-cicd-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = local.eks_gitlab_worker_role_arn
        },
        Action    = "sts:AssumeRole",
        Condition = {}
      }
    ]
  })
}

resource "aws_iam_role_policy" "cicd_ecr_policy" {
  name   = "${local.project_name}-cicd-ecr-policy"
  role   = aws_iam_role.cicd_cross_account_role.name
  policy = data.aws_iam_policy_document.cicd.json
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.project_name}-ecs-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
  name = "${local.project_name}-ecs-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ecs_task_cognito" {
  name = "${local.project_name}-ecs-task-cognito"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cognito-idp:AdminCreateUser",
          "cognito-idp:AdminUpdateUserAttributes",
          "cognito-idp:AdminDeleteUser",
          "cognito-idp:AdminGetUser",
          "cognito-idp:ListUsers",
          "cognito-idp:AdminSetUserPassword",
          "cognito-idp:AdminEnableUser",
          "cognito-idp:AdminDisableUser"
        ],
        Resource = [
          aws_cognito_user_pool.main.arn,
          "${aws_cognito_user_pool.main.arn}/*",
          aws_cognito_user_pool.backoffice.arn,
          "${aws_cognito_user_pool.backoffice.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_cognito_attach" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_task_cognito.arn
}

resource "aws_iam_policy" "ecs_task_logs" {
  name = "${local.project_name}-ecs-task-logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = ["arn:aws:logs:${local.region}:${local.account_id}:log-group:/ecs/${local.ecs_cluster}:*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_logs_attach" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_task_logs.arn
}

# Role and Policy for Cognito Custom Message Lambda

resource "aws_iam_role" "cognito_custom_message_lambda_role" {
  name = "cognito-custom-message-lambda-role-${local.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "cognito_custom_message_lambda_policy" {
  name        = "cognito-custom-message-lambda-policy-${local.environment}"
  description = "Policy for Cognito Custom Message Lambda"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cognito_custom_message_lambda_policy_attachment" {
  role       = aws_iam_role.cognito_custom_message_lambda_role.name
  policy_arn = aws_iam_policy.cognito_custom_message_lambda_policy.arn
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.github_oidc_thumbprints
}

# GitHub Action OIDC provider and role for deploying Portal Frontend application

data "aws_iam_policy_document" "github_frontend_deployment" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.frontend.arn]
    effect    = "Allow"
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = ["${aws_s3_bucket.frontend.arn}/*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "github_frontend_deployment" {
  name        = "${local.project_name}-github-frontend-deployment"
  description = "Least-privilege policy for GitHub Actions to publish to frontend bucket"
  policy      = data.aws_iam_policy_document.github_frontend_deployment.json
}

resource "aws_iam_role" "github_actions_frontend_deployment" {
  name = "${local.project_name}-github-actions-frontend-deployment"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Federated = aws_iam_openid_connect_provider.github.arn },
        Action    = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          },
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:${var.github_org}/hywater-portal-frontend:*"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_frontend_deployment_attachment" {
  role       = aws_iam_role.github_actions_frontend_deployment.name
  policy_arn = aws_iam_policy.github_frontend_deployment.arn
}

# GitHub Action OIDC provider and role for deploying Portal Backend application

data "aws_iam_policy_document" "github_backend_deployment" {
  statement {
    sid = "ECRAuthAndPush"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:BatchGetImage",
      "ecr:DescribeRepositories",
      "ecr:CreateRepository"
    ]
    resources = ["*"]
  }

  statement {
    sid = "ECRRepoActions"
    actions = [
      "ecr:GetRepositoryPolicy",
      "ecr:SetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:DeleteRepositoryPolicy"
    ]
    resources = [aws_ecr_repository.api.arn]
  }

  statement {
    sid = "ECSUpdateService"
    actions = [
      "ecs:DescribeServices",
      "ecs:DescribeClusters",
      "ecs:UpdateService"
    ]
    resources = [
      aws_ecs_cluster.main.arn,
      aws_ecs_service.api.id
    ]
  }
}

resource "aws_iam_policy" "github_backend_deployment" {
  name        = "${local.project_name}-github-backend-deployment"
  description = "Least-privilege policy for GitHub Actions to deploy backend to ECR and ECS"
  policy      = data.aws_iam_policy_document.github_backend_deployment.json
}

resource "aws_iam_role" "github_actions_backend_deployment" {
  name = "${local.project_name}-github-actions-backend-deployment"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Federated = aws_iam_openid_connect_provider.github.arn },
        Action    = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          },
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:${var.github_org}/hywater-portal-backend:*"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_backend_deployment_attachment" {
  role       = aws_iam_role.github_actions_backend_deployment.name
  policy_arn = aws_iam_policy.github_backend_deployment.arn
}

# GitHub Action OIDC provider and role for infra plan access

data "aws_iam_policy_document" "github_infra_plan" {
  statement {
    sid = "EKSReadOnly"
    actions = [
      "eks:ListClusters",
      "eks:DescribeCluster",
      "eks:ListNodegroups",
      "eks:DescribeNodegroup",
      "eks:ListFargateProfiles",
      "eks:DescribeFargateProfile",
      "eks:ListAddons",
      "eks:DescribeAddon"
    ]
    resources = ["*"]
  }

  statement {
    sid = "SecretsManagerReadOnly"
    actions = [
      "secretsmanager:ListSecrets",
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue"
    ]
    resources = ["*"]
  }

  statement {
    sid = "S3ReadOnly"
    actions = [
      "s3:ListAllMyBuckets",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:GetObjectTagging"
    ]
    resources = ["*"]
  }

  statement {
    sid = "DynamoDBReadOnly"
    actions = [
      "dynamodb:ListTables",
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]
    resources = ["*"]
  }

  statement {
    sid = "DynamoDBStateLocking"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:UpdateItem",
      "dynamodb:GetItem",
      "dynamodb:DescribeTable"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "github_infra_plan" {
  name        = "${local.project_name}-github-infra-plan"
  description = "Read-only policy for GitHub Actions infra plan access"
  policy      = data.aws_iam_policy_document.github_infra_plan.json
}

resource "aws_iam_role" "github_actions_infra_plan" {
  name = "${local.project_name}-github-actions-infra-pr"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Federated = aws_iam_openid_connect_provider.github.arn },
        Action    = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          },
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:${var.github_org}/hywater-portal-infra:*"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_infra_plan_attachment" {
  role       = aws_iam_role.github_actions_infra_plan.name
  policy_arn = aws_iam_policy.github_infra_plan.arn
}

# GitHub Action OIDC provider and role for deploying Backoffice application

data "aws_iam_policy_document" "github_backoffice_deployment" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.backoffice.arn]
    effect    = "Allow"
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = ["${aws_s3_bucket.backoffice.arn}/*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "github_backoffice_deployment" {
  name        = "${local.project_name}-github-backoffice-deployment"
  description = "Least-privilege policy for GitHub Actions to publish to backoffice bucket"
  policy      = data.aws_iam_policy_document.github_backoffice_deployment.json
}

resource "aws_iam_role" "github_actions_backoffice_deployment" {
  name = "${local.project_name}-github-actions-backoffice-deployment"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Federated = aws_iam_openid_connect_provider.github.arn },
        Action    = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          },
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:${var.github_org}/hywater-portal-backoffice:*"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_backoffice_deployment_attachment" {
  role       = aws_iam_role.github_actions_backoffice_deployment.name
  policy_arn = aws_iam_policy.github_backoffice_deployment.arn
}

# GitHub Actions OIDC role for Lambdas deployment and Terraform state management

data "aws_iam_policy_document" "github_lambda_deployment" {
  # Lambda artifacts bucket
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetBucketPolicy",
      "s3:GetBucketAcl",
      "s3:GetBucketCORS",
      "s3:GetBucketWebsite",
      "s3:GetBucketVersioning",
      "s3:GetAccelerateConfiguration",
      "s3:GetBucketRequestPayment",
      "s3:GetBucketLogging",
      "s3:GetLifecycleConfiguration",
      "s3:GetReplicationConfiguration",
      "s3:GetEncryptionConfiguration",
      "s3:GetBucketObjectLockConfiguration",
      "s3:GetBucketTagging",
      "s3:GetObjectTagging",
      "s3:GetObjectVersion"
    ]
    resources = [aws_s3_bucket.bucket_lambdas.arn]
    effect    = "Allow"
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:HeadObject",
      "s3:GetObjectVersion",
      "s3:GetObjectTagging"
    ]
    resources = ["${aws_s3_bucket.bucket_lambdas.arn}/*"]
    effect    = "Allow"
  }

  # Terraform state bucket + lock table
  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.project_name}-terraform-state"]
    effect    = "Allow"
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:HeadObject",
      "s3:GetObjectVersion"
    ]
    resources = ["arn:aws:s3:::${local.project_name}-terraform-state/*"]
    effect    = "Allow"
  }

  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:UpdateItem"
    ]
    resources = [
      "arn:aws:dynamodb:us-west-2:${local.account_id}:table/${local.project_name}-terraform-state-lock"
    ]
    effect = "Allow"
  }

  # Allow CICD role to read roles used for Lambdas (covers all roles in the account)
  statement {
    actions = [
      "iam:GetRole",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies"
    ]
    resources = [
      "arn:aws:iam::${local.account_id}:role/*"
    ]
    effect = "Allow"
  }

  # Necessary for custom Cognito message Lambda
  statement {
    actions = ["cognito-idp:DescribeUserPool", "cognito-idp:GetUserPoolMfaConfig"]
    resources = [
      aws_cognito_user_pool.main.arn,
      aws_cognito_user_pool.backoffice.arn
    ]
    effect = "Allow"
  }

  # Allow CICD role to read Lambda functions (covers all functions in the account/region)
  statement {
    actions = [
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:GetPolicy",
      "lambda:ListVersionsByFunction",
      "lambda:GetFunctionCodeSigningConfig",
      "lambda:UpdateFunctionCode"
    ]
    resources = [
      "arn:aws:lambda:${local.region}:${local.account_id}:function:*"
    ]
    effect = "Allow"
  }

  statement {
    actions = [
      "ses:DescribeConfigurationSet",
      "ses:GetConfigurationSet",
      "ses:ListConfigurationSets"
    ]
    resources = [
      "*"
    ]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "github_lambda_deployment" {
  name        = "${local.project_name}-github-lambda-deployment"
  description = "Least-privilege policy for GitHub Actions to push lambda artifacts and apply targeted OpenTofu changes"
  policy      = data.aws_iam_policy_document.github_lambda_deployment.json
}

resource "aws_iam_role" "github_actions_lambda_deployment" {
  name = "${local.project_name}-github-actions-lambda-deployment"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Federated = aws_iam_openid_connect_provider.github.arn },
        Action    = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          },
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:${var.github_org}/hywater-portal-infra:*"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_lambda_deployment_attachment" {
  role       = aws_iam_role.github_actions_lambda_deployment.name
  policy_arn = aws_iam_policy.github_lambda_deployment.arn
}

# GitHub Action OIDC role for infra deployment (plan/apply)
resource "aws_iam_role" "github_actions_infra_deployment" {
  name = "${local.project_name}-github-actions-infra-deployment"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Federated = aws_iam_openid_connect_provider.github.arn },
        Action    = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          },
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:${var.github_org}/hywater-portal-infra:*"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_infra_deployment_admin" {
  role       = aws_iam_role.github_actions_infra_deployment.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
