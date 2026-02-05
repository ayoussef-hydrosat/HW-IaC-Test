package staging

import (
	"strings"
	"testing"

	awssdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/cloudfront"
	"github.com/aws/aws-sdk-go/service/route53"
	"github.com/stretchr/testify/require"
	infra "hywater-portal-infra-staging-validation-tests"
)

// Validate CloudFront distributions exist for frontend and backoffice domains.
func TestCloudFrontDistributionsConfigured(t *testing.T) {
	t.Parallel()

	region := infra.RequireRegion(t)
	outputs := infra.LoadOutputs(t)
	zoneID := infra.OutputString(t, outputs, "zone_id")

	r53 := route53.New(infra.AwsSession(t, region))
	zoneOut, err := r53.GetHostedZone(&route53.GetHostedZoneInput{
		Id: awssdk.String(zoneID),
	})
	require.NoError(t, err)
	zoneName := strings.TrimSuffix(awssdk.StringValue(zoneOut.HostedZone.Name), ".")
	require.NotEmpty(t, zoneName)

	frontendAlias := zoneName
	backofficeAlias := "admin." + zoneName

	cf := cloudfront.New(infra.AwsSession(t, "us-east-1"))
	distOut, err := cf.ListDistributions(&cloudfront.ListDistributionsInput{})
	require.NoError(t, err)
	require.NotNil(t, distOut.DistributionList)

	var frontendFound bool
	var backofficeFound bool
	for _, dist := range distOut.DistributionList.Items {
		if dist == nil || dist.Aliases == nil {
			continue
		}
		aliases := awssdk.StringValueSlice(dist.Aliases.Items)
		if infra.ContainsString(aliases, frontendAlias) {
			frontendFound = true
			require.True(t, awssdk.BoolValue(dist.Enabled), "frontend CloudFront distribution should be enabled")
			require.Equal(t, cloudfront.ViewerProtocolPolicyRedirectToHttps, awssdk.StringValue(dist.DefaultCacheBehavior.ViewerProtocolPolicy))
		}
		if infra.ContainsString(aliases, backofficeAlias) {
			backofficeFound = true
			require.True(t, awssdk.BoolValue(dist.Enabled), "backoffice CloudFront distribution should be enabled")
			require.Equal(t, cloudfront.ViewerProtocolPolicyRedirectToHttps, awssdk.StringValue(dist.DefaultCacheBehavior.ViewerProtocolPolicy))
		}
	}

	require.True(t, frontendFound, "missing frontend CloudFront distribution for %s", frontendAlias)
	require.True(t, backofficeFound, "missing backoffice CloudFront distribution for %s", backofficeAlias)
}
