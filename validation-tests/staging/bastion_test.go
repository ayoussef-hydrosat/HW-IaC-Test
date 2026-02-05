package staging

import (
	"testing"

	awssdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/stretchr/testify/require"
	infra "hywater-portal-infra-staging-validation-tests"
)

// Validate bastion host is running in a public subnet with the expected public IP.
func TestBastionHostConfig(t *testing.T) {
	t.Parallel()

	region := infra.RequireRegion(t)
	outputs := infra.LoadOutputs(t)
	publicIP := infra.OutputString(t, outputs, "bastion_public_ip")
	publicSubnets := infra.OutputStringSlice(t, outputs, "public_subnets")

	client := ec2.New(infra.AwsSession(t, region))
	out, err := client.DescribeInstances(&ec2.DescribeInstancesInput{
		Filters: []*ec2.Filter{
			{
				Name:   awssdk.String("ip-address"),
				Values: awssdk.StringSlice([]string{publicIP}),
			},
		},
	})
	require.NoError(t, err)

	var instance *ec2.Instance
	for _, reservation := range out.Reservations {
		for _, inst := range reservation.Instances {
			if inst != nil && inst.PublicIpAddress != nil && *inst.PublicIpAddress == publicIP {
				instance = inst
				break
			}
		}
	}
	require.NotNil(t, instance, "bastion instance not found for public IP")
	require.Equal(t, "running", awssdk.StringValue(instance.State.Name))
	require.NotNil(t, instance.SubnetId)
	require.True(t, infra.ContainsString(publicSubnets, awssdk.StringValue(instance.SubnetId)))
}
