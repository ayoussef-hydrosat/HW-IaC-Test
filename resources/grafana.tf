# IAM role for Grafana Cloud to read CloudWatch metrics
resource "aws_iam_role" "grafana_cloud" {
  name = "${local.project_name}-grafana-cloud"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${var.grafana_cloud_account_id}:root"
        },
        Action = "sts:AssumeRole",
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.grafana_cloud_external_id
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "grafana_cloud_cloudwatch" {
  name = "${local.project_name}-grafana-cloud-cloudwatch"
  role = aws_iam_role.grafana_cloud.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowReadingMetricsFromCloudWatch",
        Effect = "Allow",
        Action = [
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetInsightRuleReport"
        ],
        Resource = "*"
      },
      {
        Sid    = "AllowReadingTagsInstancesRegionsFromEC2",
        Effect = "Allow",
        Action = [
          "ec2:DescribeTags",
          "ec2:DescribeInstances",
          "ec2:DescribeRegions"
        ],
        Resource = "*"
      },
      {
        Sid      = "AllowReadingResourcesForTags",
        Effect   = "Allow",
        Action   = "tag:GetResources",
        Resource = "*"
      },
      {
        Sid      = "AllowReadingResourceMetricsFromPerformanceInsights",
        Effect   = "Allow",
        Action   = "pi:GetResourceMetrics",
        Resource = "*"
      }
    ]
  })
}