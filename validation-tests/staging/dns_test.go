package staging

import (
	"testing"

	awssdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/acm"
	"github.com/aws/aws-sdk-go/service/route53"
	"github.com/stretchr/testify/require"
	infra "hywater-portal-infra-staging-validation-tests"
)

// Validate Route53 hosted zone exists and nameservers match outputs.
func TestDnsHostedZoneConfig(t *testing.T) {
	t.Parallel()

	region := infra.RequireRegion(t)
	outputs := infra.LoadOutputs(t)
	zoneID := infra.OutputString(t, outputs, "zone_id")
	nameservers := infra.OutputStringSlice(t, outputs, "nameservers")

	client := route53.New(infra.AwsSession(t, region))
	out, err := client.GetHostedZone(&route53.GetHostedZoneInput{
		Id: awssdk.String(zoneID),
	})
	require.NoError(t, err)
	require.NotNil(t, out.HostedZone)
	require.NotEmpty(t, awssdk.StringValue(out.HostedZone.Name))
	require.NotNil(t, out.DelegationSet)
	require.NotEmpty(t, out.DelegationSet.NameServers)

	for _, ns := range nameservers {
		require.True(t, infra.ContainsString(awssdk.StringValueSlice(out.DelegationSet.NameServers), ns))
	}
}

// Validate ACM certificates are present and issued for main and CloudFront.
func TestAcmCertificatesIssued(t *testing.T) {
	t.Parallel()

	region := infra.RequireRegion(t)
	outputs := infra.LoadOutputs(t)
	arns := infra.OutputStringMap(t, outputs, "certificate_arns")

	mainArn := arns["main"]
	cloudfrontArn := arns["cloudfront"]
	require.NotEmpty(t, mainArn)
	require.NotEmpty(t, cloudfrontArn)

	mainClient := acm.New(infra.AwsSession(t, region))
	mainOut, err := mainClient.DescribeCertificate(&acm.DescribeCertificateInput{
		CertificateArn: awssdk.String(mainArn),
	})
	require.NoError(t, err)
	require.Equal(t, acm.CertificateStatusIssued, awssdk.StringValue(mainOut.Certificate.Status))

	cfClient := acm.New(infra.AwsSession(t, "us-east-1"))
	cfOut, err := cfClient.DescribeCertificate(&acm.DescribeCertificateInput{
		CertificateArn: awssdk.String(cloudfrontArn),
	})
	require.NoError(t, err)
	require.Equal(t, acm.CertificateStatusIssued, awssdk.StringValue(cfOut.Certificate.Status))
}
