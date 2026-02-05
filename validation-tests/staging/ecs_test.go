package staging

import (
	"strconv"
	"testing"

	awssdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ecs"
	awstt "github.com/gruntwork-io/terratest/modules/aws"
	"github.com/stretchr/testify/require"
	infra "hywater-portal-infra-staging-validation-tests"
)

// Validate ECS desired count stays within configured bounds.
func TestEcsServiceDesiredCountWithinBounds(t *testing.T) {
	t.Parallel()

	region := infra.RequireRegion(t)
	outputs := infra.LoadOutputs(t)
	cluster := infra.OutputString(t, outputs, "ecs_cluster_name")
	service := infra.OutputString(t, outputs, "ecs_service_name")
	minAllowed := infra.OutputInt64(t, outputs, "ecs_desired_min")
	maxAllowed := infra.OutputInt64(t, outputs, "ecs_desired_max")

	svc := awstt.GetEcsService(t, region, cluster, service)
	desired := int64(svc.DesiredCount)

	require.GreaterOrEqual(t, desired, minAllowed, "ECS desired count too low")
	require.LessOrEqual(t, desired, maxAllowed, "ECS desired count too high")
}

// Validate ECS service configuration (Fargate, circuit breaker, private subnets).
func TestEcsServiceConfig(t *testing.T) {
	t.Parallel()

	region := infra.RequireRegion(t)
	outputs := infra.LoadOutputs(t)
	cluster := infra.OutputString(t, outputs, "ecs_cluster_name")
	service := infra.OutputString(t, outputs, "ecs_service_name")
	privateSubnets := infra.OutputStringSlice(t, outputs, "private_subnets")

	client := ecs.New(infra.AwsSession(t, region))
	out, err := client.DescribeServices(&ecs.DescribeServicesInput{
		Cluster:  awssdk.String(cluster),
		Services: awssdk.StringSlice([]string{service}),
	})
	require.NoError(t, err)
	require.Len(t, out.Services, 1)

	svc := out.Services[0]
	require.Equal(t, "ACTIVE", awssdk.StringValue(svc.Status))
	require.Equal(t, "FARGATE", awssdk.StringValue(svc.LaunchType))
	require.GreaterOrEqual(t, awssdk.Int64Value(svc.RunningCount), int64(1), "ECS service should have running tasks")

	circuit := svc.DeploymentConfiguration.DeploymentCircuitBreaker
	require.NotNil(t, circuit)
	require.True(t, awssdk.BoolValue(circuit.Enable), "ECS deployment circuit breaker should be enabled")
	require.True(t, awssdk.BoolValue(circuit.Rollback), "ECS deployment circuit breaker should rollback")

	awsvpc := svc.NetworkConfiguration.AwsvpcConfiguration
	require.NotNil(t, awsvpc)
	require.ElementsMatch(t, privateSubnets, awssdk.StringValueSlice(awsvpc.Subnets))
}

// Validate ECS task definition uses awsvpc, Fargate sizing, and port 3000.
func TestEcsTaskDefinitionConfig(t *testing.T) {
	t.Parallel()

	region := infra.RequireRegion(t)
	outputs := infra.LoadOutputs(t)
	cluster := infra.OutputString(t, outputs, "ecs_cluster_name")
	service := infra.OutputString(t, outputs, "ecs_service_name")

	client := ecs.New(infra.AwsSession(t, region))
	svcOut, err := client.DescribeServices(&ecs.DescribeServicesInput{
		Cluster:  awssdk.String(cluster),
		Services: awssdk.StringSlice([]string{service}),
	})
	require.NoError(t, err)
	require.Len(t, svcOut.Services, 1)

	taskDefArn := awssdk.StringValue(svcOut.Services[0].TaskDefinition)
	require.NotEmpty(t, taskDefArn)

	tdOut, err := client.DescribeTaskDefinition(&ecs.DescribeTaskDefinitionInput{
		TaskDefinition: awssdk.String(taskDefArn),
	})
	require.NoError(t, err)
	taskDef := tdOut.TaskDefinition
	require.NotNil(t, taskDef)
	require.Equal(t, "awsvpc", awssdk.StringValue(taskDef.NetworkMode))
	require.Contains(t, awssdk.StringValueSlice(taskDef.RequiresCompatibilities), "FARGATE")

	cpu, err := strconv.Atoi(awssdk.StringValue(taskDef.Cpu))
	require.NoError(t, err)
	require.GreaterOrEqual(t, cpu, 256)

	memory, err := strconv.Atoi(awssdk.StringValue(taskDef.Memory))
	require.NoError(t, err)
	require.GreaterOrEqual(t, memory, 512)

	var apiContainer *ecs.ContainerDefinition
	for _, container := range taskDef.ContainerDefinitions {
		if awssdk.StringValue(container.Name) == "api" {
			apiContainer = container
			break
		}
	}
	require.NotNil(t, apiContainer, "api container must exist in task definition")

	portOK := false
	for _, mapping := range apiContainer.PortMappings {
		if mapping != nil && mapping.ContainerPort != nil && *mapping.ContainerPort == 3000 {
			portOK = true
			break
		}
	}
	require.True(t, portOK, "api container must expose port 3000")

	if apiContainer.LogConfiguration != nil {
		require.Equal(t, "awsfirelens", awssdk.StringValue(apiContainer.LogConfiguration.LogDriver))
	}
}
