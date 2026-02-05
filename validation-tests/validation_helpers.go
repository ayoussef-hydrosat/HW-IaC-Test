package tests

import (
	"encoding/json"
	"os"
	"strings"
	"testing"

	awssdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/aws/aws-sdk-go/service/rds"
	"github.com/stretchr/testify/require"
)

type TfOutput struct {
	Value any `json:"value"`
}

type TfOutputs map[string]TfOutput

func LoadOutputs(t *testing.T) TfOutputs {
	t.Helper()

	path := os.Getenv("TF_OUTPUTS_FILE")
	if path == "" {
		path = "staging-outputs.json"
	}

	data, err := os.ReadFile(path)
	require.NoError(t, err, "failed to read outputs file")

	var outputs TfOutputs
	require.NoError(t, json.Unmarshal(data, &outputs), "failed to parse outputs json")
	return outputs
}

func OutputString(t *testing.T, outputs TfOutputs, key string) string {
	t.Helper()
	out, ok := outputs[key]
	require.True(t, ok, "missing output: %s", key)
	val, ok := out.Value.(string)
	require.True(t, ok, "output %s is not a string", key)
	return val
}

func OutputInt64(t *testing.T, outputs TfOutputs, key string) int64 {
	t.Helper()
	out, ok := outputs[key]
	require.True(t, ok, "missing output: %s", key)
	switch v := out.Value.(type) {
	case float64:
		return int64(v)
	case int64:
		return v
	case int:
		return int64(v)
	default:
		require.FailNow(t, "output is not numeric", "output %s has unsupported type %T", key, out.Value)
		return 0
	}
}

func OutputStringSlice(t *testing.T, outputs TfOutputs, key string) []string {
	t.Helper()
	out, ok := outputs[key]
	require.True(t, ok, "missing output: %s", key)
	switch v := out.Value.(type) {
	case []any:
		values := make([]string, 0, len(v))
		for i, item := range v {
			str, ok := item.(string)
			require.True(t, ok, "output %s[%d] is not a string", key, i)
			values = append(values, str)
		}
		return values
	case []string:
		return v
	default:
		require.FailNow(t, "output is not a string list", "output %s has unsupported type %T", key, out.Value)
		return nil
	}
}

func OutputStringMap(t *testing.T, outputs TfOutputs, key string) map[string]string {
	t.Helper()
	out, ok := outputs[key]
	require.True(t, ok, "missing output: %s", key)
	switch v := out.Value.(type) {
	case map[string]any:
		result := make(map[string]string, len(v))
		for k, raw := range v {
			value, ok := raw.(string)
			require.True(t, ok, "output %s[%s] is not a string", key, k)
			result[k] = value
		}
		return result
	case map[string]string:
		return v
	default:
		require.FailNow(t, "output is not a string map", "output %s has unsupported type %T", key, out.Value)
		return nil
	}
}

func RequireRegion(t *testing.T) string {
	t.Helper()
	region := os.Getenv("AWS_REGION")
	require.NotEmpty(t, region, "AWS_REGION must be set")
	return region
}

func AwsSession(t *testing.T, region string) *session.Session {
	t.Helper()
	sess, err := session.NewSessionWithOptions(session.Options{
		Config:            awssdk.Config{Region: awssdk.String(region)},
		SharedConfigState: session.SharedConfigEnable,
	})
	require.NoError(t, err)
	return sess
}

func ContainsString(values []string, needle string) bool {
	for _, value := range values {
		if value == needle {
			return true
		}
	}
	return false
}

func FindRdsByEndpoint(client *rds.RDS, endpoint string) (*rds.DBInstance, error) {
	out, err := client.DescribeDBInstances(&rds.DescribeDBInstancesInput{})
	if err != nil {
		return nil, err
	}
	for _, inst := range out.DBInstances {
		if inst == nil || inst.Endpoint == nil || inst.Endpoint.Address == nil {
			continue
		}
		if *inst.Endpoint.Address == endpoint {
			return inst, nil
		}
	}
	return nil, nil
}

func StripPort(endpoint string) string {
	if strings.Contains(endpoint, ":") {
		parts := strings.Split(endpoint, ":")
		if len(parts) > 0 {
			return parts[0]
		}
	}
	return endpoint
}

func RoleNameFromArn(arn string) string {
	parts := strings.Split(arn, "/")
	return parts[len(parts)-1]
}

func SubnetHasIgwRoute(client *ec2.EC2, vpcID, subnetID string) (bool, error) {
	rtOut, err := client.DescribeRouteTables(&ec2.DescribeRouteTablesInput{
		Filters: []*ec2.Filter{
			{
				Name:   awssdk.String("association.subnet-id"),
				Values: awssdk.StringSlice([]string{subnetID}),
			},
		},
	})
	if err != nil {
		return false, err
	}

	routeTables := rtOut.RouteTables
	if len(routeTables) == 0 {
		mainOut, err := client.DescribeRouteTables(&ec2.DescribeRouteTablesInput{
			Filters: []*ec2.Filter{
				{
					Name:   awssdk.String("vpc-id"),
					Values: awssdk.StringSlice([]string{vpcID}),
				},
				{
					Name:   awssdk.String("association.main"),
					Values: awssdk.StringSlice([]string{"true"}),
				},
			},
		})
		if err != nil {
			return false, err
		}
		routeTables = mainOut.RouteTables
	}

	for _, table := range routeTables {
		for _, route := range table.Routes {
			if route == nil || route.GatewayId == nil {
				continue
			}
			if strings.HasPrefix(awssdk.StringValue(route.GatewayId), "igw-") {
				return true, nil
			}
		}
	}

	return false, nil
}

func ProjectNameFromCognitoDomain(domain string) string {
	return strings.TrimSuffix(domain, "-auth")
}

func EnvironmentFromProjectName(projectName string) string {
	parts := strings.Split(projectName, "-")
	if len(parts) == 0 {
		return ""
	}
	return parts[len(parts)-1]
}
