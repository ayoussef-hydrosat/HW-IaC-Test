package staging

import (
	"testing"

	awssdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/eks"
	"github.com/stretchr/testify/require"
	infra "hywater-portal-infra-staging-validation-tests"
)

// Validate EKS monitoring cluster is active and on the expected version.
func TestEksClusterConfig(t *testing.T) {
	t.Parallel()

	region := infra.RequireRegion(t)
	outputs := infra.LoadOutputs(t)
	eksClusterName := infra.OutputString(t, outputs, "eks_cluster_name")
	require.NotEmpty(t, eksClusterName)

	client := eks.New(infra.AwsSession(t, region))
	out, err := client.DescribeCluster(&eks.DescribeClusterInput{
		Name: awssdk.String(eksClusterName),
	})
	require.NoError(t, err)
	require.NotNil(t, out.Cluster)
	require.Equal(t, eks.ClusterStatusActive, awssdk.StringValue(out.Cluster.Status))
	require.Equal(t, "1.32", awssdk.StringValue(out.Cluster.Version))
}

// Validate EKS Alloy node group exists and has sane scaling settings.
func TestEksAlloyNodeGroupConfig(t *testing.T) {
	t.Parallel()

	region := infra.RequireRegion(t)
	outputs := infra.LoadOutputs(t)
	eksClusterName := infra.OutputString(t, outputs, "eks_cluster_name")
	require.NotEmpty(t, eksClusterName)

	client := eks.New(infra.AwsSession(t, region))
	out, err := client.DescribeNodegroup(&eks.DescribeNodegroupInput{
		ClusterName:   awssdk.String(eksClusterName),
		NodegroupName: awssdk.String("alloy"),
	})
	require.NoError(t, err)
	require.NotNil(t, out.Nodegroup)
	require.NotNil(t, out.Nodegroup.ScalingConfig)
	require.GreaterOrEqual(t, awssdk.Int64Value(out.Nodegroup.ScalingConfig.MinSize), int64(1))
	require.GreaterOrEqual(t, awssdk.Int64Value(out.Nodegroup.ScalingConfig.DesiredSize), int64(1))
	require.GreaterOrEqual(t, awssdk.Int64Value(out.Nodegroup.ScalingConfig.MaxSize), awssdk.Int64Value(out.Nodegroup.ScalingConfig.DesiredSize))
}
