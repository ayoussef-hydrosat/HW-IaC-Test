package terraform
import rego.v1

# Policy
# Require Helm releases to pin a chart version.
deny contains msg if {
  rc := input.resource_changes[_]
  rc.type == "helm_release"
  after := rc.change.after
  after != null
  after.version == ""
  msg := sprintf("Helm release must pin a chart version: %s", [rc.address])
}

# Tests

test_helm_version_pinned if {
  msg := deny[_] with input as input_helm_no_version
  msg == "Helm release must pin a chart version: helm_release.grafana"
}

# Fixtures

input_helm_no_version := {
  "resource_changes": [
    {
      "type": "helm_release",
      "address": "helm_release.grafana",
      "change": { "after": { "version": "" } }
    }
  ]
}
