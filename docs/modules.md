# Modules

Six modules, all under `modules/`. Each directory is a standalone Terraform
module with its own `variables.tf`, `outputs.tf` and README; the environment
examples compose them.

| Module | Creates | Cost driver | Main outputs |
| --- | --- | --- | --- |
| [`network`](../modules/network/README.md) | VPC, public/private subnets, IGW, NAT, routes | NAT gateways and data processing | `vpc_id`, subnet ids |
| [`ecs-service`](../modules/ecs-service/README.md) | Fargate service, task definition, log group, IAM roles, service SG | Fargate vCPU/GB and logs | cluster/service ids, `service_security_group_id`, log group |
| [`rds`](../modules/rds/README.md) | PostgreSQL instance, subnet group, parameter group, SG | instance hours, storage, backups | `endpoint`, `port`, `resource_id` |
| [`static-site`](../modules/static-site/README.md) | private S3 bucket, CloudFront distribution, OAC, bucket policy | CloudFront requests and egress | `distribution_id`, `site_url` |
| [`alarms`](../modules/alarms/README.md) | SNS topic, subscriptions, CloudWatch alarms | alarm count and SNS notifications | `sns_topic_arn`, `alarm_names` |
| [`budget`](../modules/budget/README.md) | AWS Budget with forecast notifications | none (AWS Budgets first two are free) | `budget_name`, `budget_id` |

## Wiring

```hcl
module "network" {
  source = "../../modules/network"
  name   = local.name
}

module "service" {
  source             = "../../modules/ecs-service"
  cluster_name       = "${local.name}-cluster"
  service_name       = "${local.name}-api"
  container_image    = var.container_image
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
}

module "rds" {
  source                     = "../../modules/rds"
  name                       = "${local.name}-db"
  vpc_id                     = module.network.vpc_id
  subnet_ids                 = module.network.private_subnet_ids
  ingress_security_group_ids = [module.service.service_security_group_id]
  password                   = var.db_password
}
```

The database does not expose its endpoint into the service module, because that
would create a dependency cycle: the database ingress already depends on the
service security group. The application receives its connection string from the
environment or Secrets Manager, not from a Terraform output wired back into the
same task definition.

## Conventions

- Every variable and output has a `description`; the validator enforces it.
- Tags are passed in as `map(string)` and merged with resource names.
- No module creates a public IP for a database, bucket or task.
- Optional components are controlled by empty inputs plus `count`, not by
  nullable required arguments.
- Resources are named `this` when a module creates exactly one of them.

## Adding a module

1. Create `modules/<name>/` with `main.tf`, `variables.tf`, `outputs.tf` and a
   README that has `## Inputs` and `## Outputs` tables.
2. Add the name to `MODULES` in `src/validate.js`.
3. Wire it into `examples/dev` and `examples/prod`, or document why not.
4. Run `node scripts/validate.mjs` and `node scripts/build-data.mjs`.
