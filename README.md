# Portal staging

Folder `portal-staging` is all the OpenTofu code that defines HyWater portal, backoffice, backend AWS resources for staging environment.

# Portal production

Folder `portal-production` is all the OpenTofu code that defines HyWater portal, backoffice, backend AWS resources for production environment.

# Variables

Both environments expect Grafana & Alloy variables to be set in their `terraform.tfvars` files:

- `grafana_cloud_account_id`
- `grafana_cloud_external_id`
- `grafana_loki_endpoint`
- `grafana_loki_username`
- `grafana_loki_tenant_id`
- `alloy_otlp_host`
- `alloy_otlp_lb_zone_id`

The current values are stored in LastPass; copy them from the vault and place them in `portal-staging/terraform.tfvars` and `portal-production/terraform.tfvars` before running tofu.

# Lambdas

The logic is defined in `lambdas` folder, which is a node TypeScript app.

When merging this repo on main, the CI/CD

- builds the lambdas into different bundle per lambda subfolder
- create one .zip file per bundle
- upload the files on S3 in lambdas bucket
- apply the terraform code (based on aws image, the CI installs OpenTofu via command line) for the lambdas only to redeploy them

## To add a new lambda

- Add the lambda definition in `lambdas.tf` for both `portal-production` and `portal-staging`
- Add a new folder in `lambdas/src`. The build script searches for folders in src to build a lambda per folder so the structure matters. The entry point of the lambda, where the handler function is implemented, must have the same name as the folder so the CI can find it.
- Add the command in `.gitlab-ci.yml` for the new lambda. Example : `tofu apply -auto-approve -target=aws_lambda_function.cognito_custom_message_lambda`


```
├── lambdas
│   ├── src
│   │   ├── <lambda_name_1>
│   │       ├──<lambda_name_1>.ts
│   │       ├──utils
│   │       ├── ...
│   │       ├──services
│   │   ├── <lambda_name_2>
│   │       ├──<lambda_name_2>.ts
│   │       ├──utils
│   │       ├── ...
│   │       ├──messages
├── portal-staging
├── portal-production

```

The <lambda_name_1> folder can contain any files and subfolders we want that will be used to compile the lambda, as long as the entrypoint `handler` is on a file with the same name.
