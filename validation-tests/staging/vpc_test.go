package staging

import (
	"testing"

	awssdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/stretchr/testify/require"
	infra "hywater-portal-infra-staging-validation-tests"
)

// Validate VPC DNS support and hostnames are enabled.
func TestVpcDnsSupportEnabled(t *testing.T) {
	t.Parallel()

	region := infra.RequireRegion(t)
	outputs := infra.LoadOutputs(t)
	vpcID := infra.OutputString(t, outputs, "vpc_id")

	client := ec2.New(infra.AwsSession(t, region))
	dnsSupport, err := client.DescribeVpcAttribute(&ec2.DescribeVpcAttributeInput{
		VpcId:     awssdk.String(vpcID),
		Attribute: awssdk.String(ec2.VpcAttributeNameEnableDnsSupport),
	})
	require.NoError(t, err)
	require.NotNil(t, dnsSupport.EnableDnsSupport)
	require.True(t, awssdk.BoolValue(dnsSupport.EnableDnsSupport.Value), "VPC DNS support should be enabled")

	dnsHostnames, err := client.DescribeVpcAttribute(&ec2.DescribeVpcAttributeInput{
		VpcId:     awssdk.String(vpcID),
		Attribute: awssdk.String(ec2.VpcAttributeNameEnableDnsHostnames),
	})
	require.NoError(t, err)
	require.NotNil(t, dnsHostnames.EnableDnsHostnames)
	require.True(t, awssdk.BoolValue(dnsHostnames.EnableDnsHostnames.Value), "VPC DNS hostnames should be enabled")
}

// Validate public subnets route to an internet gateway and private subnets do not.
func TestSubnetPublicPrivateSettings(t *testing.T) {
	t.Parallel()

	region := infra.RequireRegion(t)
	outputs := infra.LoadOutputs(t)
	publicSubnets := infra.OutputStringSlice(t, outputs, "public_subnets")
	privateSubnets := infra.OutputStringSlice(t, outputs, "private_subnets")
	vpcID := infra.OutputString(t, outputs, "vpc_id")

	allSubnets := append(append([]string{}, publicSubnets...), privateSubnets...)
	client := ec2.New(infra.AwsSession(t, region))
	out, err := client.DescribeSubnets(&ec2.DescribeSubnetsInput{
		SubnetIds: awssdk.StringSlice(allSubnets),
	})
	require.NoError(t, err)

	subnetByID := make(map[string]*ec2.Subnet, len(out.Subnets))
	for _, subnet := range out.Subnets {
		if subnet != nil && subnet.SubnetId != nil {
			subnetByID[*subnet.SubnetId] = subnet
		}
	}

	for _, subnetID := range publicSubnets {
		_, ok := subnetByID[subnetID]
		require.True(t, ok, "missing public subnet %s", subnetID)
		hasIgw, err := infra.SubnetHasIgwRoute(client, vpcID, subnetID)
		require.NoError(t, err)
		require.True(t, hasIgw, "public subnet must route to an internet gateway: %s", subnetID)
	}

	for _, subnetID := range privateSubnets {
		_, ok := subnetByID[subnetID]
		require.True(t, ok, "missing private subnet %s", subnetID)
		hasIgw, err := infra.SubnetHasIgwRoute(client, vpcID, subnetID)
		require.NoError(t, err)
		require.False(t, hasIgw, "private subnet must not route to an internet gateway: %s", subnetID)
	}
}
