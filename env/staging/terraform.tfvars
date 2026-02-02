region       = "us-east-2"
project_name = "hywater-portal-staging"
environment  = "staging"
account_id   = "431343616446"

vpc_cidr        = "10.0.0.0/20"
azs             = ["us-east-2a", "us-east-2b"]
private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]

domain_name = "hywater-staging.hydrosat.com"

#EKS Gitlab Worker Role ARN
eks_gitlab_worker_role_arn = "arn:aws:iam::294926015719:role/eks-gitlab-worker"
ecs_cluster                = "hywater-portal"

#Database
db_name                    = "hywater"
db_username                = "postgres"
db_instance_class          = "db.t3.micro"
db_backup_retention_period = 7

# EKS / Alloy
eks_cluster_name       = "hywater-portal-monitoring"
eks_node_instance_type = "t3.large"
eks_node_desired       = 2
eks_node_min           = 1
eks_node_max           = 3

# WAF
# TODO: Currently we are using HyWater only for POC purpose. During release phase, following rate limits should be re-configured as per usecases.
waf_rate_limits = {
  webApiV1     = 100
  serviceApiV1 = 100
}
waf_log_group_name = "hywater-portal-staging-waf"

grafana_cloud_account_id  = "008923505280"
grafana_cloud_external_id = "1413427"
grafana_loki_endpoint     = "https://logs-prod-012.grafana.net/loki/api/v1/push"
grafana_loki_username     = "1371221"
grafana_loki_tenant_id    = "1371221"
alloy_otlp_host           = "aaa78056587c04f6ea548196a33ee378-1486027141.us-east-2.elb.amazonaws.com"
alloy_otlp_lb_zone_id     = "Z3AADJGX6KTTL2"
