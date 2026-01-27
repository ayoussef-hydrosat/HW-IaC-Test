run "eks_alloy_nodegroup" {
  command = plan

  variables {
    enable_cert_validation_records = false
    enable_k8s_resources           = false
  }

  assert {
    condition     = aws_eks_node_group.alloy.scaling_config[0].desired_size >= 2
    error_message = "Alloy desired_size must be >= 2"
  }

  assert {
    condition     = aws_eks_node_group.alloy.scaling_config[0].min_size >= 1
    error_message = "Alloy min_size must be >= 1"
  }

  assert {
    condition     = aws_eks_node_group.alloy.scaling_config[0].max_size >= aws_eks_node_group.alloy.scaling_config[0].desired_size
    error_message = "Alloy max_size must be >= desired_size"
  }
}

run "eks_addons" {
  command = plan

  variables {
    enable_cert_validation_records = false
    enable_k8s_resources           = false
  }

  assert {
    condition     = aws_eks_cluster.monitoring.version == "1.32"
    error_message = "EKS cluster version must be 1.32"
  }

  assert {
    condition     = aws_eks_cluster.monitoring.access_config[0].authentication_mode == "API_AND_CONFIG_MAP"
    error_message = "EKS cluster must use API_AND_CONFIG_MAP authentication"
  }

  assert {
    condition     = aws_eks_addon.coredns.addon_name == "coredns"
    error_message = "CoreDNS addon must be enabled"
  }

  assert {
    condition     = aws_eks_addon.ebs_csi.addon_name == "aws-ebs-csi-driver"
    error_message = "EBS CSI addon must be enabled"
  }
}
