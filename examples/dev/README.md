# Development stack

A cheap version of the baseline: one NAT-free network, a single-AZ PostgreSQL
instance, one ECS task, a static site, alarms and a budget.

```bash
cd examples/dev
terraform init
export TF_VAR_db_password="$(openssl rand -hex 24)"
terraform plan
```

This example deliberately turns off the things that cost money or add safety:
NAT gateways, Multi-AZ and deletion protection. It still keeps the database
private, encryption at rest, forced SSL, least-privilege task roles and the
alarms. That is the point of a dev environment: cheaper, not less correct.

The ECS service has no load balancer in this repository, so the service
security group output is meant to be attached to whatever ALB or API gateway
the application uses.

## What runs

| Module | Dev settings |
| --- | --- |
| `network` | 2 AZs, no NAT gateways |
| `rds` | `db.t3.micro`, single AZ, 1-day backups, no deletion protection |
| `ecs-service` | 1 task, 256 CPU / 512 MiB |
| `static-site` | private bucket, CloudFront, no custom domain |
| `alarms` | ECS and RDS alarms, no ALB alarms |
| `budget` | monthly budget with 80% and 100% forecasts |

## State

This example has no backend block, so state lives locally. For a shared dev
environment, copy the `backend "s3"` block described in `docs/state.md` and
pass the bucket and table with `-backend-config`. Do not commit `terraform.tfstate`.
