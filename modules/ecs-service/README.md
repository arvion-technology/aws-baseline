# ecs-service

Runs one container on ECS Fargate with a task definition, a log group, two IAM
roles and a security group that only allows egress.

The two roles are separate on purpose. The execution role pulls the image,
writes logs and reads the Secrets Manager ARNs listed in `secrets` (and only
those). The task role is what the application itself can do, and starts with
permission to write its own logs, no wildcard, no `*` resource. Attach the
permissions the service actually needs to the task role in the calling
configuration.

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `cluster_name` | `string` | required | ECS cluster name |
| `service_name` | `string` | required | Service and IAM role name |
| `container_image` | `string` | required | Image reference |
| `container_port` | `number` | `8080` | Container port |
| `health_check_path` | `string` | `/health` | Health check path |
| `cpu` / `memory` | `string` | `512` / `1024` | Fargate sizing |
| `desired_count` | `number` | `2` | Initial task count |
| `vpc_id` | `string` | required | VPC for the security group |
| `private_subnet_ids` | `list(string)` | required | Task subnets |
| `environment` | `map(string)` | `{}` | Plain env vars |
| `secrets` | `map(string)` | `{}` | Env var name to secret ARN |
| `log_retention_days` | `number` | `30` | Log retention |
| `tags` | `map(string)` | `{}` | Tags |

## Outputs

| Name | Description |
| --- | --- |
| `cluster_arn` / `cluster_name` | Cluster identifiers |
| `service_name` | Service name |
| `service_security_group_id` | Attach this to the load balancer |
| `task_definition_arn` | Current task definition |
| `log_group_name` | Log group |

## Notes

There is no load balancer in this module, so the service ignores
`load_balancer` and the security group has no ingress rules. Wire the returned
security group into your ALB target group. The container health check calls
`curl`, which must exist in the image; use a distroless image only if you
replace the check with an ECS-native alternative.
