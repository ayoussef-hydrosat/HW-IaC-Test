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

variable "enable_cert_validation_records" {
  description = "Enable Route53 certificate validation records"
  type        = bool
  default     = true
}

variable "enable_k8s_resources" {
  description = "Enable Kubernetes and Helm resources"
  type        = bool
  default     = true
}
