###############################################
# EKS core (roles, cluster, addons)
###############################################

# EKS cluster role
resource "aws_iam_role" "eks_cluster" {
  name = "${local.project_name}-eks-cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# Node group role
resource "aws_iam_role" "eks_node" {
  name = "${local.project_name}-eks-node"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ])

  policy_arn = each.value
  role       = aws_iam_role.eks_node.name
}

# EKS monitoring cluster
resource "aws_eks_cluster" "monitoring" {
  name     = local.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.32"

  vpc_config {
    subnet_ids = module.vpc.private_subnets
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster]
}

# EKS access entry for GitHub Actions infra deployment role (AWS-native access)
resource "aws_eks_access_entry" "github_actions_infra_deployment" {
  cluster_name  = aws_eks_cluster.monitoring.name
  principal_arn = aws_iam_role.github_actions_infra_deployment.arn
}

resource "aws_eks_access_policy_association" "github_actions_infra_deployment_admin" {
  cluster_name  = aws_eks_cluster.monitoring.name
  principal_arn = aws_iam_role.github_actions_infra_deployment.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.github_actions_infra_deployment]
}

# OIDC provider for IRSA
data "tls_certificate" "eks" {
  url = aws_eks_cluster.monitoring.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.monitoring.identity[0].oidc[0].issuer
}

locals {
  eks_oidc_provider = replace(aws_iam_openid_connect_provider.eks.url, "https://", "")
}

# Alloy node group
resource "aws_eks_node_group" "alloy" {
  cluster_name    = aws_eks_cluster.monitoring.name
  node_group_name = "alloy"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = module.vpc.private_subnets

  scaling_config {
    desired_size = local.eks_node_desired
    min_size     = local.eks_node_min
    max_size     = local.eks_node_max
  }

  instance_types = [local.eks_node_instance_type]

  depends_on = [aws_iam_role_policy_attachment.eks_node]
}

# CoreDNS addon
resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.monitoring.name
  addon_name                  = "coredns"
  resolve_conflicts_on_update = "OVERWRITE"
  configuration_values = jsonencode({
    autoScaling = {
      enabled     = true
      minReplicas = 2
      maxReplicas = 5
    }
  })

  depends_on = [aws_eks_node_group.alloy]
}

# EBS CSI driver addon
resource "aws_iam_role" "ebs_csi" {
  name = "${local.project_name}-eks-ebs-csi"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRoleWithWebIdentity"
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.eks.arn }
      Condition = {
        StringEquals = {
          "${local.eks_oidc_provider}:aud" : "sts.amazonaws.com",
          "${local.eks_oidc_provider}:sub" : "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi.name
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = aws_eks_cluster.monitoring.name
  addon_name                  = "aws-ebs-csi-driver"
  service_account_role_arn    = aws_iam_role.ebs_csi.arn
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_iam_role_policy_attachment.ebs_csi]
}
