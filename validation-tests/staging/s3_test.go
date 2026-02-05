package staging

import (
	"strings"
	"testing"

	awssdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/cloudfront"
	"github.com/aws/aws-sdk-go/service/route53"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/stretchr/testify/require"
	infra "hywater-portal-infra-staging-validation-tests"
)

// Validate S3 buckets behind CloudFront have strict public access blocks.
func TestS3PublicAccessBlocks(t *testing.T) {
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

	buckets := make(map[string]struct{})
	for _, dist := range distOut.DistributionList.Items {
		if dist == nil || dist.Aliases == nil {
			continue
		}
		aliases := awssdk.StringValueSlice(dist.Aliases.Items)
		if !infra.ContainsString(aliases, frontendAlias) && !infra.ContainsString(aliases, backofficeAlias) {
			continue
		}
		for _, origin := range dist.Origins.Items {
			if origin == nil || origin.DomainName == nil {
				continue
			}
			domain := awssdk.StringValue(origin.DomainName)
			if strings.Contains(domain, ".s3") {
				bucket := strings.Split(domain, ".")[0]
				if bucket != "" {
					buckets[bucket] = struct{}{}
				}
			}
		}
	}

	require.NotEmpty(t, buckets, "no CloudFront-backed S3 buckets found")

	s3Client := s3.New(infra.AwsSession(t, region))
	for bucket := range buckets {
		blockOut, err := s3Client.GetPublicAccessBlock(&s3.GetPublicAccessBlockInput{
			Bucket: awssdk.String(bucket),
		})
		require.NoError(t, err, "missing public access block for bucket %s", bucket)
		cfg := blockOut.PublicAccessBlockConfiguration
		require.NotNil(t, cfg, "missing public access block config for bucket %s", bucket)
		require.True(t, awssdk.BoolValue(cfg.BlockPublicAcls), "bucket %s must block public ACLs", bucket)
		require.True(t, awssdk.BoolValue(cfg.IgnorePublicAcls), "bucket %s must ignore public ACLs", bucket)
		require.True(t, awssdk.BoolValue(cfg.RestrictPublicBuckets), "bucket %s must restrict public buckets", bucket)
	}
}
