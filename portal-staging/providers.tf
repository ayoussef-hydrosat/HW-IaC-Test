provider "aws" {
  region = local.region
}
# Required for CloudFront ACM certificate validation, which must be in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "kubernetes" {
  # When enable_k8s_resources is false, use placeholder values so tests can run without a live cluster.
  host                   = var.enable_k8s_resources ? try(data.aws_eks_cluster.alloy[0].endpoint, "https://example.invalid") : "https://example.invalid"
  cluster_ca_certificate = var.enable_k8s_resources ? base64decode(local.eks_ca_data) : local.eks_test_ca
  token                  = var.enable_k8s_resources ? try(data.aws_eks_cluster_auth.alloy[0].token, "dummy") : "dummy"
}

provider "helm" {
  kubernetes {
    # When enable_k8s_resources is false, use placeholder values so tests can run without a live cluster.
    host                   = var.enable_k8s_resources ? try(data.aws_eks_cluster.alloy[0].endpoint, "https://example.invalid") : "https://example.invalid"
    cluster_ca_certificate = var.enable_k8s_resources ? base64decode(local.eks_ca_data) : local.eks_test_ca
    token                  = var.enable_k8s_resources ? try(data.aws_eks_cluster_auth.alloy[0].token, "dummy") : "dummy"
  }
}