# network

Creates the VPC, public and private subnets across the requested availability
zones, an internet gateway, one NAT gateway per AZ and the route tables that
connect them.

Private subnets are the default home for ECS tasks and RDS. The NAT gateways
exist so those private tasks can pull an image and call an external API; they
are not used for inbound traffic. Set `enable_nat_gateway = false` for a
development environment that only needs private egress through a VPC endpoint
or does not need internet access at all.

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `name` | `string` | required | Prefix for every network resource |
| `cidr` | `string` | `10.0.0.0/16` | VPC CIDR |
| `az_count` | `number` | `2` | Availability zones to use (2-3) |
| `public_subnet_cidrs` | `list(string)` | `10.0.0.0/24...` | One public CIDR per AZ |
| `private_subnet_cidrs` | `list(string)` | `10.0.10.0/24...` | One private CIDR per AZ |
| `enable_nat_gateway` | `bool` | `true` | Create one NAT gateway per AZ |
| `tags` | `map(string)` | `{}` | Tags applied to everything |

## Outputs

| Name | Description |
| --- | --- |
| `vpc_id` | VPC id |
| `public_subnet_ids` | Public subnet ids in AZ order |
| `private_subnet_ids` | Private subnet ids in AZ order |
| `nat_gateway_ids` | NAT gateway ids |
| `vpc_cidr` | VPC CIDR |

## Notes

This module does not create VPC endpoints. For production workloads that only
talk to S3 and ECR, add gateway/interface endpoints and drop the NAT gateways;
that changes the cost profile more than any other decision in the baseline.
