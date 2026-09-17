# rds

Creates a PostgreSQL instance in private subnets with encryption at rest,
forced SSL, Performance Insights, automated backups and a security group whose
only ingress is from the security groups the caller lists.

`publicly_accessible` is hard-coded to `false`. There is no variable to turn it
on: a baseline that allows a public database is not a baseline. Connectivity is
through the security group, which the calling configuration wires from the ECS
service.

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `name` | `string` | required | Database identifier |
| `engine` | `string` | `postgres` | Engine |
| `engine_version` | `string` | `15.7` | Version |
| `parameter_group_family` | `string` | `postgres15` | Must match the major version |
| `instance_class` | `string` | `db.t3.micro` | Instance size |
| `allocated_storage` | `number` | `20` | GiB |
| `db_name`, `username` | `string` | `app` | Initial database and master user |
| `password` | `string` | required, sensitive | Master password |
| `vpc_id`, `subnet_ids` | | required | Network placement |
| `ingress_security_group_ids` | `list(string)` | `[]` | Allowed clients |
| `backup_retention_period` | `number` | `7` | Days |
| `multi_az` | `bool` | `false` | Standby replica |
| `deletion_protection` | `bool` | `true` | Also enables the final snapshot |
| `performance_insights_enabled` | `bool` | `true` | Performance Insights |
| `log_retention_days` | `number` | `30` | PostgreSQL logs |

## Outputs

| Name | Description |
| --- | --- |
| `endpoint` | host:port |
| `address`, `port` | Connection details |
| `database_name` | Initial database |
| `security_group_id` | Database security group |
| `resource_id` | Id for CloudWatch alarms |

## Notes

The password is a required sensitive variable with no default, so a plan cannot
silently create a database with a known password. Rotating it is out of scope;
use Secrets Manager with `manage_master_user_password = true` when the provider
version supports it.
