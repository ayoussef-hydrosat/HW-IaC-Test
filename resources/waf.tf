locals {
  waf_name       = "${local.project_name}-waf"
  metric_prefix  = local.environment
  base_tags      = { Environment = local.environment }
  log_group_name = "aws-waf-logs-${local.waf_name}"
  search_strings = {
    web_api_v1     = "/web-api/v1"
    service_api_v1 = "/api/v1"
  }
}

resource "aws_wafv2_ip_set" "blocked" {
  count = length(var.waf_blocked_ip_addresses) > 0 ? 1 : 0

  name               = "${local.waf_name}-blocked-ips"
  description        = "Blocked IPs for the ${local.environment} environment."
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = var.waf_blocked_ip_addresses
}

resource "aws_wafv2_web_acl" "portal" {
  name        = local.waf_name
  description = "Portal WAF for the ${local.environment} environment."
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.metric_prefix}_allow"
    sampled_requests_enabled   = true
  }

  dynamic "rule" {
    for_each = length(var.waf_blocked_ip_addresses) > 0 ? [1] : []
    content {
      name     = "block-listed-ips"
      priority = 0

      action {
        block {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.blocked[0].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.metric_prefix}-block-ipv4"
        sampled_requests_enabled   = true
      }
    }
  }

  rule {
    name     = "aws-managed-common-rule-set"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.metric_prefix}-aws-crs"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "web-api-v1-rate-limit"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = local.waf_rate_limits.webApiV1
        aggregate_key_type = "IP"

        scope_down_statement {
          byte_match_statement {
            search_string         = local.search_strings.web_api_v1
            positional_constraint = "CONTAINS"
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.metric_prefix}-web-api-v1-rate"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "service-api-v1-rate-limit"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = local.waf_rate_limits.serviceApiV1
        aggregate_key_type = "IP"

        scope_down_statement {
          byte_match_statement {
            search_string         = local.search_strings.service_api_v1
            positional_constraint = "CONTAINS"
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.metric_prefix}-service-api-v1-rate"
      sampled_requests_enabled   = true
    }
  }

  tags = local.base_tags
}

resource "aws_cloudwatch_log_group" "waf" {
  name              = local.log_group_name
  retention_in_days = 30
}

resource "aws_cloudwatch_log_resource_policy" "waf_logs" {
  policy_name = "waf-to-cw-logs"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSWAFLoggingPermissions"
        Effect = "Allow"

        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }

        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]

        Resource = "${aws_cloudwatch_log_group.waf.arn}:*"
      }
    ]
  })
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  resource_arn            = aws_wafv2_web_acl.portal.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]
}
