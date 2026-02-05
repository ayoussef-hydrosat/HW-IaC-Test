package staging

import (
	"testing"

	awssdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/cognitoidentityprovider"
	"github.com/stretchr/testify/require"
	infra "hywater-portal-infra-staging-validation-tests"
)

// Validate main Cognito user pool and client security settings.
func TestCognitoUserPoolConfig(t *testing.T) {
	t.Parallel()

	region := infra.RequireRegion(t)
	outputs := infra.LoadOutputs(t)
	userPoolID := infra.OutputString(t, outputs, "cognito_user_pool_id")
	clientID := infra.OutputString(t, outputs, "cognito_user_pool_client_id")

	client := cognitoidentityprovider.New(infra.AwsSession(t, region))
	poolOut, err := client.DescribeUserPool(&cognitoidentityprovider.DescribeUserPoolInput{
		UserPoolId: awssdk.String(userPoolID),
	})
	require.NoError(t, err)
	require.NotNil(t, poolOut.UserPool)

	policy := poolOut.UserPool.Policies.PasswordPolicy
	require.NotNil(t, policy)
	require.GreaterOrEqual(t, awssdk.Int64Value(policy.MinimumLength), int64(8))
	require.True(t, awssdk.BoolValue(policy.RequireLowercase))
	require.True(t, awssdk.BoolValue(policy.RequireUppercase))
	require.True(t, awssdk.BoolValue(policy.RequireNumbers))
	require.True(t, awssdk.BoolValue(policy.RequireSymbols))
	require.Equal(t, "OPTIONAL", awssdk.StringValue(poolOut.UserPool.MfaConfiguration))

	clientOut, err := client.DescribeUserPoolClient(&cognitoidentityprovider.DescribeUserPoolClientInput{
		UserPoolId: awssdk.String(userPoolID),
		ClientId:   awssdk.String(clientID),
	})
	require.NoError(t, err)
	require.NotNil(t, clientOut.UserPoolClient)

	flows := awssdk.StringValueSlice(clientOut.UserPoolClient.ExplicitAuthFlows)
	require.True(t, infra.ContainsString(flows, "ALLOW_USER_SRP_AUTH"))
	require.True(t, infra.ContainsString(flows, "ALLOW_REFRESH_TOKEN_AUTH"))
	require.True(t, infra.ContainsString(flows, "ALLOW_USER_PASSWORD_AUTH"))

	require.True(t, awssdk.BoolValue(clientOut.UserPoolClient.AllowedOAuthFlowsUserPoolClient))
	require.True(t, infra.ContainsString(awssdk.StringValueSlice(clientOut.UserPoolClient.AllowedOAuthFlows), "code"))

	scopes := awssdk.StringValueSlice(clientOut.UserPoolClient.AllowedOAuthScopes)
	require.True(t, infra.ContainsString(scopes, "email"))
	require.True(t, infra.ContainsString(scopes, "openid"))
	require.True(t, infra.ContainsString(scopes, "profile"))
}

// Validate backoffice Cognito user pool requires admin-created users and auth flows.
func TestBackofficeCognitoUserPoolConfig(t *testing.T) {
	t.Parallel()

	region := infra.RequireRegion(t)
	outputs := infra.LoadOutputs(t)
	userPoolID := infra.OutputString(t, outputs, "backoffice_cognito_user_pool_id")
	clientID := infra.OutputString(t, outputs, "backoffice_cognito_user_pool_client_id")

	client := cognitoidentityprovider.New(infra.AwsSession(t, region))
	poolOut, err := client.DescribeUserPool(&cognitoidentityprovider.DescribeUserPoolInput{
		UserPoolId: awssdk.String(userPoolID),
	})
	require.NoError(t, err)
	require.NotNil(t, poolOut.UserPool)
	require.NotNil(t, poolOut.UserPool.AdminCreateUserConfig)
	require.True(t, awssdk.BoolValue(poolOut.UserPool.AdminCreateUserConfig.AllowAdminCreateUserOnly))

	clientOut, err := client.DescribeUserPoolClient(&cognitoidentityprovider.DescribeUserPoolClientInput{
		UserPoolId: awssdk.String(userPoolID),
		ClientId:   awssdk.String(clientID),
	})
	require.NoError(t, err)
	require.NotNil(t, clientOut.UserPoolClient)

	flows := awssdk.StringValueSlice(clientOut.UserPoolClient.ExplicitAuthFlows)
	require.True(t, infra.ContainsString(flows, "ALLOW_USER_SRP_AUTH"))
	require.True(t, infra.ContainsString(flows, "ALLOW_REFRESH_TOKEN_AUTH"))
	require.True(t, infra.ContainsString(flows, "ALLOW_USER_PASSWORD_AUTH"))
}
