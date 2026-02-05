package staging

import (
	"testing"

	"github.com/aws/aws-sdk-go/service/rds"
	"github.com/stretchr/testify/require"
	infra "hywater-portal-infra-staging-validation-tests"
)

// Validate RDS instance security (encryption, private, backups).
func TestRdsConfigIsSecure(t *testing.T) {
	t.Parallel()

	region := infra.RequireRegion(t)
	outputs := infra.LoadOutputs(t)
	endpoint := infra.OutputString(t, outputs, "rds_endpoint")
	require.NotEmpty(t, endpoint, "rds_endpoint must not be empty")
	endpoint = infra.StripPort(endpoint)

	rdsClient := rds.New(infra.AwsSession(t, region))
	inst, err := infra.FindRdsByEndpoint(rdsClient, endpoint)
	require.NoError(t, err)
	require.NotNil(t, inst, "RDS instance not found for endpoint")

	if inst.PubliclyAccessible != nil {
		require.False(t, *inst.PubliclyAccessible, "RDS should not be publicly accessible")
	}
	if inst.StorageEncrypted != nil {
		require.True(t, *inst.StorageEncrypted, "RDS storage should be encrypted")
	}
	if inst.BackupRetentionPeriod != nil {
		require.GreaterOrEqual(t, int64(*inst.BackupRetentionPeriod), int64(7), "RDS backup retention should be >= 7 days")
	}
}

// Validate RDS subnet group uses private subnets only.
func TestRdsSubnetGroupUsesPrivateSubnets(t *testing.T) {
	t.Parallel()

	region := infra.RequireRegion(t)
	outputs := infra.LoadOutputs(t)
	endpoint := infra.OutputString(t, outputs, "rds_endpoint")
	privateSubnets := infra.OutputStringSlice(t, outputs, "private_subnets")
	endpoint = infra.StripPort(endpoint)

	rdsClient := rds.New(infra.AwsSession(t, region))
	inst, err := infra.FindRdsByEndpoint(rdsClient, endpoint)
	require.NoError(t, err)
	require.NotNil(t, inst, "RDS instance not found for endpoint")
	require.NotNil(t, inst.DBSubnetGroup)
	require.NotNil(t, inst.DBSubnetGroup.DBSubnetGroupName)

	sgOut, err := rdsClient.DescribeDBSubnetGroups(&rds.DescribeDBSubnetGroupsInput{
		DBSubnetGroupName: inst.DBSubnetGroup.DBSubnetGroupName,
	})
	require.NoError(t, err)
	require.Len(t, sgOut.DBSubnetGroups, 1)

	privateSet := make(map[string]struct{}, len(privateSubnets))
	for _, subnetID := range privateSubnets {
		privateSet[subnetID] = struct{}{}
	}

	for _, subnet := range sgOut.DBSubnetGroups[0].Subnets {
		if subnet == nil || subnet.SubnetIdentifier == nil {
			continue
		}
		_, ok := privateSet[*subnet.SubnetIdentifier]
		require.True(t, ok, "RDS subnet group must use private subnet: %s", *subnet.SubnetIdentifier)
	}
}
