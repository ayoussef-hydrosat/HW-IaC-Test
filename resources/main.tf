module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.20.0"

  name = "${local.project_name}-vpc"
  cidr = local.vpc_cidr
  azs  = local.azs

  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_flow_log                                 = true
  create_flow_log_cloudwatch_log_group            = true
  create_flow_log_cloudwatch_iam_role             = true
  flow_log_max_aggregation_interval               = 600
  flow_log_cloudwatch_log_group_retention_in_days = 30

  manage_default_network_acl = true
  default_network_acl_tags = {
    Name = "${local.project_name}-default-nacl"
  }

  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []
  default_security_group_tags = {
    Name = "${local.project_name}-default-sg"
  }

  tags = {
    Environment = local.environment
    Project     = local.project_name
    ManagedBy   = "terraform"
    Name        = "${local.project_name}-vpc"
  }
}
