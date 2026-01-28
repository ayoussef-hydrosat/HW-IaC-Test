package terraform
import rego.v1

# Policy
# Require Kubernetes namespace name.
deny contains msg if {
  rc := input.resource_changes[_]
  rc.type == "kubernetes_namespace"
  after := rc.change.after
  after != null
  after.metadata.name == ""
  msg := sprintf("Kubernetes namespace must have a name: %s", [rc.address])
}

# Require Kubernetes secrets to have data.
deny contains msg if {
  rc := input.resource_changes[_]
  rc.type == "kubernetes_secret"
  after := rc.change.after
  after != null
  after.data == null
  msg := sprintf("Kubernetes secret must include data: %s", [rc.address])
}

# Tests

test_kubernetes_namespace_name_required if {
  msg := deny[_] with input as input_namespace_no_name
  msg == "Kubernetes namespace must have a name: kubernetes_namespace.grafana_cloud"
}

test_kubernetes_secret_data_required if {
  msg := deny[_] with input as input_secret_no_data
  msg == "Kubernetes secret must include data: kubernetes_secret.grafana_cloud_alloy"
}

# Fixtures

input_namespace_no_name := {
  "resource_changes": [
    {
      "type": "kubernetes_namespace",
      "address": "kubernetes_namespace.grafana_cloud",
      "change": { "after": { "metadata": { "name": "" } } }
    }
  ]
}

input_secret_no_data := {
  "resource_changes": [
    {
      "type": "kubernetes_secret",
      "address": "kubernetes_secret.grafana_cloud_alloy",
      "change": { "after": { "data": null } }
    }
  ]
}
