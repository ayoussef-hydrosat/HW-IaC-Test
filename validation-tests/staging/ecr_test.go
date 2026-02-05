package staging

import (
	"strings"
	"testing"

	"github.com/aws/aws-sdk-go/service/ecr"
	"github.com/stretchr/testify/require"
	infra "hywater-portal-infra-staging-validation-tests"
)

// Validate ECR repository exists for the API service.
func TestEcrRepositoryExists(t *testing.T) {
	t.Parallel()

	region := infra.RequireRegion(t)
	outputs := infra.LoadOutputs(t)
	repoURL := infra.OutputString(t, outputs, "ecr_repository_url")

	parts := strings.Split(repoURL, "/")
	require.GreaterOrEqual(t, len(parts), 2, "invalid ECR repository URL")
	repoName := parts[len(parts)-1]
	require.NotEmpty(t, repoName)

	client := ecr.New(infra.AwsSession(t, region))
	out, err := client.DescribeRepositories(&ecr.DescribeRepositoriesInput{
		RepositoryNames: []*string{&repoName},
	})
	require.NoError(t, err)
	require.Len(t, out.Repositories, 1)
	require.Equal(t, repoName, *out.Repositories[0].RepositoryName)
}
