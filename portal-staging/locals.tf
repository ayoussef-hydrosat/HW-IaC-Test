locals {
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
  db_name           = "hywater"
  db_username       = "postgres"
  db_instance_class = "db.t3.micro"

  # EKS / Alloy
  eks_cluster_name       = "hywater-portal-monitoring"
  eks_node_instance_type = "t3.large"
  eks_node_desired       = 2
  eks_node_min           = 1
  eks_node_max           = 3
}
