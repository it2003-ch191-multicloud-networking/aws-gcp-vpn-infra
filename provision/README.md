## Providers

| Name                 | Version |
| -------------------- | ------- |
| google.impersonation | 5.10.0  |

## Modules

| Name           | Source                    | Version |
| -------------- | ------------------------- | ------- |
| gcp-aws-ha-vpn | ../modules/gcp-aws-ha-vpn | n/a     |
| network        | ../modules/network        | n/a     |

## Resources

| Name                                                                                                                                                          | Type        |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [google_service_account_access_token.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/service_account_access_token) | data source |

## Inputs

| Name                        | Description                 | Type           | Default | Required |
| --------------------------- | --------------------------- | -------------- | ------- | :------: |
| aws_router_asn              | n/a                         | `string`       | n/a     |   yes    |
| aws_vpc_cidr                | n/a                         | `string`       | n/a     |   yes    |
| gcp_vpc_cidr                | n/a                         | `string`       | n/a     |   yes    |
| gcp_router_asn              | n/a                         | `string`       | n/a     |   yes    |
| impersonate_service_account | n/a                         | `string`       | n/a     |   yes    |
| network_name                | n/a                         | `string`       | n/a     |   yes    |
| num_tunnels                 | Total number of VPN tunnels | `number`       | n/a     |   yes    |
| project_id                  | n/a                         | `string`       | n/a     |   yes    |
| shared_secret               | n/a                         | `string`       | n/a     |   yes    |
| subnet_regions              | n/a                         | `list(string)` | n/a     |   yes    |
| vpn_gwy_region              | n/a                         | `string`       | n/a     |   yes    |
