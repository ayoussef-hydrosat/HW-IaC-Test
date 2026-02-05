package staging

import (
	"encoding/json"
	"net/url"
	"strings"
	"testing"

	awssdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/iam"
	"github.com/stretchr/testify/require"
	infra "hywater-portal-infra-staging-validation-tests"
)

// Validate GitHub Actions role trust policy uses the GitHub OIDC provider with scoped subjects.
func TestGithubActionsRoleTrustPolicy(t *testing.T) {
	t.Parallel()

	region := infra.RequireRegion(t)
	outputs := infra.LoadOutputs(t)
	roleArn := infra.OutputString(t, outputs, "github_actions_backoffice_deployment_role_arn")

	client := iam.New(infra.AwsSession(t, region))
	out, err := client.GetRole(&iam.GetRoleInput{
		RoleName: awssdk.String(infra.RoleNameFromArn(roleArn)),
	})
	require.NoError(t, err)
	require.NotNil(t, out.Role)

	doc, err := url.QueryUnescape(awssdk.StringValue(out.Role.AssumeRolePolicyDocument))
	require.NoError(t, err)

	var policy map[string]any
	require.NoError(t, json.Unmarshal([]byte(doc), &policy))

	statements, ok := policy["Statement"].([]any)
	require.True(t, ok, "assume role policy missing Statement")

	foundOIDC := false
	foundSub := false
	for _, stmt := range statements {
		entry, ok := stmt.(map[string]any)
		if !ok {
			continue
		}
		principal, ok := entry["Principal"].(map[string]any)
		if ok {
			if federated, ok := principal["Federated"].(string); ok && strings.Contains(federated, "token.actions.githubusercontent.com") {
				foundOIDC = true
			}
			if federatedList, ok := principal["Federated"].([]any); ok {
				for _, item := range federatedList {
					if value, ok := item.(string); ok && strings.Contains(value, "token.actions.githubusercontent.com") {
						foundOIDC = true
					}
				}
			}
		}

		if condition, ok := entry["Condition"].(map[string]any); ok {
			for _, key := range []string{"StringLike", "StringEquals"} {
				if cond, ok := condition[key].(map[string]any); ok {
					if sub, ok := cond["token.actions.githubusercontent.com:sub"].(string); ok && sub != "" {
						foundSub = true
					}
				}
			}
		}
	}

	require.True(t, foundOIDC, "assume role policy must trust GitHub OIDC provider")
	require.True(t, foundSub, "assume role policy must scope subject condition")
}
