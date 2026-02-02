locals {
  region       = var.region
  project_name = var.project_name
  environment  = var.environment
  account_id   = var.account_id

  vpc_cidr        = var.vpc_cidr
  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  domain_name = var.domain_name

  #EKS Gitlab Worker Role ARN
  eks_gitlab_worker_role_arn = var.eks_gitlab_worker_role_arn
  ecs_cluster                = var.ecs_cluster

  #Database
  db_name                    = var.db_name
  db_username                = var.db_username
  db_instance_class          = var.db_instance_class
  db_backup_retention_period = var.db_backup_retention_period

  # EKS / Alloy
  eks_cluster_name       = var.eks_cluster_name
  eks_node_instance_type = var.eks_node_instance_type
  eks_node_desired       = var.eks_node_desired
  eks_node_min           = var.eks_node_min
  eks_node_max           = var.eks_node_max

  # WAF
  # TODO: Currently we are using HyWater only for POC purpose. During release phase, following rate limits should be re-configured as per usecases.
  waf_rate_limits    = var.waf_rate_limits
  waf_log_group_name = var.waf_log_group_name
}
