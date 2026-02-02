variable "region" {
  description = "AWS region for resources"
  type        = string
}

variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., staging, production)"
  type        = string
}

variable "account_id" {
  description = "AWS account ID for this environment"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
}

variable "domain_name" {
  description = "Base domain name for DNS and certs"
  type        = string
}

variable "eks_gitlab_worker_role_arn" {
  description = "EKS Gitlab worker role ARN"
  type        = string
}

variable "ecs_cluster" {
  description = "ECS cluster name"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "db_backup_retention_period" {
  description = "RDS backup retention period (days)"
  type        = number
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "eks_node_instance_type" {
  description = "EKS node instance type"
  type        = string
}

variable "eks_node_desired" {
  description = "EKS node desired count"
  type        = number
}

variable "eks_node_min" {
  description = "EKS node min count"
  type        = number
}

variable "eks_node_max" {
  description = "EKS node max count"
  type        = number
}

variable "waf_rate_limits" {
  description = "WAF rate limits"
  type        = map(number)
}

variable "waf_log_group_name" {
  description = "WAF log group name"
  type        = string
}

variable "db_password" {
  description = "Password for the RDS PostgreSQL instance"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair for the bastion host"
  type        = string
  default     = "hywater-bastion-key"
}

variable "grafana_cloud_account_id" {
  description = "AWS account ID provided by Grafana Cloud for CloudWatch access"
  type        = string
  sensitive   = false
  default     = ""
}

variable "grafana_cloud_external_id" {
  description = "External ID provided by Grafana Cloud for the AWS integration"
  type        = string
  sensitive   = false
  default     = ""
}

variable "grafana_loki_endpoint" {
  description = "Grafana Cloud Loki endpoint for Alloy to access"
  type        = string
  sensitive   = false
  default     = ""
}

variable "grafana_loki_username" {
  description = "Username for Grafana Cloud Loki. Needed Alloy to access"
  type        = string
  sensitive   = false
  default     = ""
}

variable "grafana_loki_tenant_id" {
  description = "Tenant ID of the Grafana Cloud Loki. Needed for Alloy to access"
  type        = string
  sensitive   = false
  default     = ""
}

variable "grafana_cloud_password" {
  description = "Password for the Grafana Cloud Loki access. Defined in the Access Policy"
  type        = string
  sensitive   = true
  default     = ""
}

variable "alloy_otlp_host" {
  description = "DNS name of the Alloy OTLP receiver load balancer"
  type        = string
  sensitive   = false
  default     = ""
}

variable "alloy_otlp_lb_zone_id" {
  description = "Hosted zone ID of the Alloy OTLP receiver load balancer"
  type        = string
  sensitive   = false
  default     = ""
}

variable "github_org" {
  description = "GitHub organization/owner for OIDC trust"
  type        = string
  default     = "Hydrosat"
}

variable "github_oidc_thumbprints" {
  description = "Allowed CA thumbprints for GitHub OIDC provider"
  type        = list(string)
  default = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b7517f0f98e94daf"
  ]
}

variable "waf_blocked_ip_addresses" {
  description = "List of IPv4 addresses to block via WAF."
  type        = list(string)
  default     = []
}

variable "is_test_mode_enabled" {
  description = "Enable test mode to disable resources that require apply-time values"
  type        = bool
  default     = false
}
