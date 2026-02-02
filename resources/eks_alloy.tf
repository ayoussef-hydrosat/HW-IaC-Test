###############################################
# EKS Alloy deployment
###############################################

###############################################
# Setup Kubernetes + Helm providers
###############################################

data "aws_eks_cluster" "alloy" {
  count = var.is_test_mode_enabled ? 0 : 1
  name  = aws_eks_cluster.monitoring.name
}

data "aws_eks_cluster_auth" "alloy" {
  count = var.is_test_mode_enabled ? 0 : 1
  name  = aws_eks_cluster.monitoring.name
}

locals {
  eks_ca_data = var.is_test_mode_enabled ? null : data.aws_eks_cluster.alloy[0].certificate_authority[0].data
}

#######################################################
# Alloy deployment
#######################################################

resource "kubernetes_namespace" "grafana_cloud" {
  count = var.is_test_mode_enabled ? 0 : 1
  metadata { name = "grafana-cloud" }
}

data "aws_secretsmanager_secret_version" "grafana_cloud_alloy" {
  secret_id  = aws_secretsmanager_secret.grafana_cloud_alloy.id
  depends_on = [aws_secretsmanager_secret_version.grafana_cloud_alloy]
}

resource "kubernetes_secret" "grafana_cloud_alloy" {
  count = var.is_test_mode_enabled ? 0 : 1
  metadata {
    name      = "grafana-cloud-alloy"
    namespace = kubernetes_namespace.grafana_cloud[0].metadata[0].name
  }

  data = {
    username  = var.grafana_loki_username
    tenant_id = var.grafana_loki_tenant_id
    endpoint  = var.grafana_loki_endpoint
    password  = jsondecode(data.aws_secretsmanager_secret_version.grafana_cloud_alloy.secret_string)["password"]
  }
}

resource "helm_release" "grafana_alloy" {
  count     = var.is_test_mode_enabled ? 0 : 1
  name      = "hywater-helm-grafana"
  namespace = kubernetes_namespace.grafana_cloud[0].metadata[0].name

  repository = "https://grafana.github.io/helm-charts"
  chart      = "alloy"
  version    = "1.5.0"

  values = [
    <<-YAML
controller:
  type: daemonset

alloy:
  enableHttpServerPort: false

  configMap:
    create: true
    content: |
      logging {
        level  = "info"
        format = "logfmt"
      }

      otelcol.receiver.otlp "otlp" {
        grpc {
          endpoint = "0.0.0.0:4317"
        }
        http {
          endpoint = "0.0.0.0:4318"
        }

        output {
          logs = [otelcol.exporter.loki.default.input]
        }
      }

      otelcol.exporter.loki "default" {
        forward_to = [loki.write.grafana_loki.receiver]
      }

      loki.write "grafana_loki" {
        endpoint {
          url = sys.env("GRAFANA_LOKI_ENDPOINT")
          basic_auth {
            username = sys.env("GRAFANA_LOKI_USERNAME")
            password = sys.env("GRAFANA_LOKI_PASSWORD")
          }
        }

        external_labels = {
          app_cluster        = "${local.ecs_cluster}",
          monitoring_cluster = "${local.eks_cluster_name}",
          environment        = "${local.environment}",
          service            = "hywater-backend",
          level              = "info",
        }
      }

  extraEnv:
    - name: GRAFANA_LOKI_ENDPOINT
      valueFrom:
        secretKeyRef:
          name: grafana-cloud-alloy
          key: endpoint
    - name: GRAFANA_LOKI_USERNAME
      valueFrom:
        secretKeyRef:
          name: grafana-cloud-alloy
          key: username
    - name: GRAFANA_LOKI_PASSWORD
      valueFrom:
        secretKeyRef:
          name: grafana-cloud-alloy
          key: password

  extraPorts:
    - name: otlp-grpc
      port: 4317
      targetPort: 4317
      protocol: TCP
    - name: otlp-http
      port: 4318
      targetPort: 4318
      protocol: TCP

service:
  enabled: true
  type: LoadBalancer

YAML
  ]

  atomic           = true
  cleanup_on_fail  = true
  wait             = true
  timeout          = 600
  create_namespace = false

  depends_on = [
    kubernetes_namespace.grafana_cloud,
    kubernetes_secret.grafana_cloud_alloy,
    aws_eks_node_group.alloy,
    aws_eks_addon.coredns,
    aws_eks_addon.ebs_csi
  ]
}

locals {
  # Test-only certificate used when test mode is enabled to satisfy provider config.
  eks_test_ca = <<-PEM
-----BEGIN CERTIFICATE-----
MIIBaDCCAQ6gAwIBAgIRAOgLq0qj2e6l7vUeZQ5sZ5kwCgYIKoZIzj0EAwIwEDEO
MAwGA1UEAwwFZHVtbXkwHhcNMjAwMTAxMDAwMDAwWhcNMzAwMTAxMDAwMDAwWjAQ
MQ4wDAYDVQQDDAVkdW1teTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABNq1lBqD
uX6sw9mNjQ4u1P2X8+f5TGNFqJw5QmE2Q8n+zZg2Zg1c4xZfX2EJ3D9k/4R6rKQy
5uTQ2m/8pj2jUzBRMB0GA1UdDgQWBBR2C2dF2m1qJX1iQ0N9qz0eUkR0WTAfBgNV
HSMEGDAWgBR2C2dF2m1qJX1iQ0N9qz0eUkR0WTAPBgNVHRMBAf8EBTADAQH/MAoG
CCqGSM49BAMCA0cAMEQCICCSWmD2JgL05t6ZX6mE6oPD58x35H5TADaBrZEcD3Mp
AiBqk0U8nyCLlcQFV3ayhtq/Y5cHIxHmr18bODsPwhj/Kw==
-----END CERTIFICATE-----
PEM
}
