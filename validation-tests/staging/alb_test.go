package staging

import (
	"testing"

	awssdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/elbv2"
	"github.com/stretchr/testify/require"
	infra "hywater-portal-infra-staging-validation-tests"
)

// Validate ALB target group has at least one healthy target.
func TestAlbTargetGroupHasHealthyTargets(t *testing.T) {
	t.Parallel()

	region := infra.RequireRegion(t)
	outputs := infra.LoadOutputs(t)
	tgArn := infra.OutputString(t, outputs, "alb_target_group_arn")

	elb := elbv2.New(infra.AwsSession(t, region))
	out, err := elb.DescribeTargetHealth(&elbv2.DescribeTargetHealthInput{
		TargetGroupArn: awssdk.String(tgArn),
	})
	require.NoError(t, err)

	healthy := 0
	for _, d := range out.TargetHealthDescriptions {
		if d.TargetHealth != nil && d.TargetHealth.State != nil && *d.TargetHealth.State == "healthy" {
			healthy++
		}
	}
	require.Greater(t, healthy, 0, "expected at least one healthy target in target group")
}

// Validate ALB target group health check and port configuration.
func TestAlbTargetGroupConfig(t *testing.T) {
	t.Parallel()

	region := infra.RequireRegion(t)
	outputs := infra.LoadOutputs(t)
	tgArn := infra.OutputString(t, outputs, "alb_target_group_arn")

	elb := elbv2.New(infra.AwsSession(t, region))
	tgOut, err := elb.DescribeTargetGroups(&elbv2.DescribeTargetGroupsInput{
		TargetGroupArns: awssdk.StringSlice([]string{tgArn}),
	})
	require.NoError(t, err)
	require.Len(t, tgOut.TargetGroups, 1)

	tg := tgOut.TargetGroups[0]
	require.Equal(t, int64(3000), awssdk.Int64Value(tg.Port))
	require.Equal(t, "HTTP", awssdk.StringValue(tg.Protocol))
	require.Equal(t, "ip", awssdk.StringValue(tg.TargetType))
	require.Equal(t, "/health", awssdk.StringValue(tg.HealthCheckPath))
	require.Equal(t, int64(2), awssdk.Int64Value(tg.HealthyThresholdCount))
	require.Equal(t, int64(10), awssdk.Int64Value(tg.UnhealthyThresholdCount))
}

// Validate ALB listeners redirect HTTP to HTTPS and forward HTTPS to target group.
func TestAlbListenersConfigured(t *testing.T) {
	t.Parallel()

	region := infra.RequireRegion(t)
	outputs := infra.LoadOutputs(t)
	tgArn := infra.OutputString(t, outputs, "alb_target_group_arn")

	elb := elbv2.New(infra.AwsSession(t, region))
	tgOut, err := elb.DescribeTargetGroups(&elbv2.DescribeTargetGroupsInput{
		TargetGroupArns: awssdk.StringSlice([]string{tgArn}),
	})
	require.NoError(t, err)
	require.Len(t, tgOut.TargetGroups, 1)

	lbArns := tgOut.TargetGroups[0].LoadBalancerArns
	require.NotEmpty(t, lbArns)

	listOut, err := elb.DescribeListeners(&elbv2.DescribeListenersInput{
		LoadBalancerArn: lbArns[0],
	})
	require.NoError(t, err)

	var httpListener *elbv2.Listener
	var httpsListener *elbv2.Listener
	for _, listener := range listOut.Listeners {
		switch awssdk.Int64Value(listener.Port) {
		case 80:
			httpListener = listener
		case 443:
			httpsListener = listener
		}
	}
	require.NotNil(t, httpListener, "expected HTTP listener on port 80")
	require.NotNil(t, httpsListener, "expected HTTPS listener on port 443")

	require.NotEmpty(t, httpListener.DefaultActions)
	httpAction := httpListener.DefaultActions[0]
	require.Equal(t, "redirect", awssdk.StringValue(httpAction.Type))
	require.NotNil(t, httpAction.RedirectConfig)
	require.Equal(t, "HTTPS", awssdk.StringValue(httpAction.RedirectConfig.Protocol))
	require.Equal(t, "443", awssdk.StringValue(httpAction.RedirectConfig.Port))
	require.Equal(t, "HTTP_301", awssdk.StringValue(httpAction.RedirectConfig.StatusCode))

	require.NotEmpty(t, httpsListener.DefaultActions)
	httpsAction := httpsListener.DefaultActions[0]
	require.Equal(t, "forward", awssdk.StringValue(httpsAction.Type))
	require.NotNil(t, httpsAction.TargetGroupArn)
	require.Equal(t, tgArn, awssdk.StringValue(httpsAction.TargetGroupArn))
}
