# alarms

CloudWatch alarms for the ECS service and, optionally, the RDS instance and the
load balancer. Every alarm notifies one SNS topic, created here unless
`sns_topic_arn` points at an existing one.

The ALB alarms are conditional on both ARN suffixes being supplied, and the RDS
alarms on the instance id. That is why the dev example can use the same module
without a load balancer: absent inputs mean absent alarms, not null dimensions.

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `name_prefix` | `string` | required | Alarm name prefix |
| `ecs_cluster_name`, `ecs_service_name` | `string` | required | ECS dimensions |
| `rds_instance_id` | `string` | `""` | Enables RDS alarms |
| `alb_arn_suffix`, `target_group_arn_suffix` | `string` | `""` | Enables ALB alarms |
| `sns_topic_arn` | `string` | `""` | Use an existing topic |
| `alert_emails` | `list(string)` | `[]` | Topic subscribers |
| `ecs_cpu_threshold` | `number` | `80` | Percent |
| `ecs_memory_threshold` | `number` | `80` | Percent |
| `rds_cpu_threshold` | `number` | `80` | Percent |
| `rds_free_storage_bytes` | `number` | 5 GiB | Bytes |
| `target_5xx_threshold` | `number` | `10` | Count per period |
| `target_latency_ms` | `number` | `2000` | p95 milliseconds |
| `period_seconds` | `number` | `300` | Alarm period |

## Outputs

| Name | Description |
| --- | --- |
| `sns_topic_arn` | Notification topic |
| `alarm_names` | Created alarm names |

## Notes

Alarms are not a substitute for a dashboard. The thresholds are starting
points, not tuned values: after two weeks of real traffic, set them from the
observed p95 rather than leaving the defaults in place. SNS email subscriptions
require confirming the link sent by AWS.
