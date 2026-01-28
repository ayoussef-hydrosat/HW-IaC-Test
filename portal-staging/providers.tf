provider "aws" {
  region = local.region
}
# Required for CloudFront ACM certificate validation, which must be in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "kubernetes" {
  # When test mode is enabled, use placeholder values so tests can run without a live cluster.
  host                   = var.is_test_mode_enabled ? "https://example.invalid" : try(data.aws_eks_cluster.alloy[0].endpoint, "https://example.invalid")
  cluster_ca_certificate = var.is_test_mode_enabled ? local.eks_test_ca : base64decode(local.eks_ca_data)
  token                  = var.is_test_mode_enabled ? "dummy" : try(data.aws_eks_cluster_auth.alloy[0].token, "dummy")
}

provider "helm" {
  kubernetes {
    # When test mode is enabled, use placeholder values so tests can run without a live cluster.
    host                   = var.is_test_mode_enabled ? "https://example.invalid" : try(data.aws_eks_cluster.alloy[0].endpoint, "https://example.invalid")
    cluster_ca_certificate = var.is_test_mode_enabled ? local.eks_test_ca : base64decode(local.eks_ca_data)
    token                  = var.is_test_mode_enabled ? "dummy" : try(data.aws_eks_cluster_auth.alloy[0].token, "dummy")
  }
}
