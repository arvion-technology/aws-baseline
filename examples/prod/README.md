# Production stack

The same modules as `dev`, with the settings that survive real traffic: three
AZs, NAT gateways, a Multi-AZ database with deletion protection and 14-day
backups, 90-day logs, load-balancer alarms and a larger budget.

```bash
cd examples/prod
terraform init -backend-config="bucket=REPLACE_ME" -backend-config="region=ap-south-1"
export TF_VAR_db_password="$(aws secretsmanager get-secret-value --secret-id prod/db --query SecretString --output text)"
terraform plan -var-file=production.tfvars
```

The `backend "s3"` block is commented out on purpose. Hard-coding a state bucket
in an example invites two teams to overwrite each other's state; pass the bucket
and lock table through `-backend-config` from CI.

## Differences from dev

| Setting | Dev | Prod |
| --- | --- | --- |
| Availability zones | 2 | 3 |
| NAT gateways | none | one per AZ |
| RDS | single AZ, `db.t3.micro`, no deletion protection | Multi-AZ, `db.m6g.large`, deletion protection, final snapshot |
| Backups | 1 day | 14 days |
| ECS tasks | 1 × 256 CPU | 3 × 1024 CPU |
| Log retention | 7 days | 90 days |
| Load-balancer alarms | disabled | enabled when ARN suffixes are supplied |
| Budget thresholds | 80, 100% | 50, 80, 100% |

## Before applying

1. Create the S3 state bucket and lock table once, outside this stack.
2. Put the database password in Secrets Manager and read it in CI.
3. Pin the container image by digest.
4. Point `alert_emails` at an on-call list and confirm the SNS subscriptions.
5. Attach the returned `service_security_group_id` to the ALB target group.
