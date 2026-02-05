package staging

import (
	"strings"
	"testing"

	awssdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/lambda"
	"github.com/stretchr/testify/require"
	infra "hywater-portal-infra-staging-validation-tests"
)

// Validate Cognito custom message lambda exists and uses the expected runtime.
func TestLambdaCognitoCustomMessage(t *testing.T) {
	t.Parallel()

	region := infra.RequireRegion(t)
	outputs := infra.LoadOutputs(t)
	cognitoDomain := infra.OutputString(t, outputs, "cognito_domain")
	projectName := infra.ProjectNameFromCognitoDomain(cognitoDomain)
	require.NotEmpty(t, projectName)

	environment := infra.EnvironmentFromProjectName(projectName)
	require.NotEmpty(t, environment)

	functionName := "cognito-custom-message-lambda-" + environment

	client := lambda.New(infra.AwsSession(t, region))
	out, err := client.GetFunctionConfiguration(&lambda.GetFunctionConfigurationInput{
		FunctionName: awssdk.String(functionName),
	})
	require.NoError(t, err)
	require.Equal(t, "nodejs20.x", awssdk.StringValue(out.Runtime))
	require.True(t, strings.HasPrefix(awssdk.StringValue(out.Handler), "index."))
}
