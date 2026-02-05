output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "cognito_user_pool_id" {
  description = "The ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_user_pool_client_id" {
  description = "The ID of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.client.id
}

output "backoffice_cognito_user_pool_id" {
  description = "The ID of the Backoffice Cognito User Pool"
  value       = aws_cognito_user_pool.backoffice.id
}

output "backoffice_cognito_user_pool_client_id" {
  description = "The ID of the Backoffice Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.backoffice_client.id
}

output "cognito_domain" {
  value = aws_cognito_user_pool_domain.main.domain
}

output "cicd_access_key" {
  value     = aws_iam_access_key.cicd.id
  sensitive = true
}

output "cicd_secret_key" {
  value     = aws_iam_access_key.cicd.secret
  sensitive = true
}

output "ecr_repository_url" {
  value = aws_ecr_repository.api.repository_url
}

output "api_endpoint" {
  value = "https://api.${local.domain_name}"
}

output "ecs_cluster" {
  value = aws_ecs_cluster.main.arn
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = aws_ecs_service.api.name
}

output "eks_cluster_name" {
  description = "EKS monitoring cluster name"
  value       = aws_eks_cluster.monitoring.name
}

output "alb_target_group_arn" {
  value = aws_lb_target_group.api.arn
}

output "ecs_desired_min" {
  value = aws_appautoscaling_target.api.min_capacity
}

output "ecs_desired_max" {
  value = aws_appautoscaling_target.api.max_capacity
}

output "rds_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = aws_db_instance.postgresql.endpoint
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "github_actions_backoffice_deployment_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC to publish backoffice assets"
  value       = aws_iam_role.github_actions_backoffice_deployment.arn
}
