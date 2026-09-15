# Architecture

The baseline is six small modules and two environments that compose them. There
is no root module per environment hidden behind workspaces; `examples/dev` and
`examples/prod` are ordinary root modules, which makes a plan readable and a
diff obvious.

```text
                       Route 53 / ACM (outside this repo)
                                   │
                            ┌──────▼──────┐
                            │ static-site │  S3 (private) + CloudFront OAC
                            └─────────────┘
                                   ▲
                                   │ uploads from CI
                                   │
                     ┌─────────────┴──────────────┐
                     │                            │
              ┌──────▼──────┐              ┌──────▼──────┐
   internet ─►│     ALB     │              │   budget    │  monthly + forecast
              │ (caller)    │              └─────────────┘
              └──────┬──────┘
                     │ target group (caller attaches
                     │ the service security group)
              ┌──────▼──────┐         ┌───────────────┐
              │ ecs-service │────────►│    alarms     │  SNS + CloudWatch
              │ Fargate     │         └───────▲───────┘
              └──────┬──────┘                 │
                     │ private subnets        │ RDS metrics
              ┌──────▼──────┐                 │
              │     rds     │─────────────────┘
              │ PostgreSQL  │  private, encrypted, forced SSL
              └──────┬──────┘
                     │
              ┌──────▼──────┐
              │   network   │  VPC, 2-3 AZs, public/private subnets, NAT
              └─────────────┘
```

## Decisions worth reviewing

**Modules own one failure domain each.** `network` owns addressing and egress,
`ecs-service` owns one service and its IAM, `rds` owns one database, and
`alarms` owns the notification path. A root module composes them with explicit
inputs. A change to the database never touches the VPC plan.

**The database is private, without a switch.** `publicly_accessible` is not a
variable. The security group accepts ingress only from security groups passed by
the caller, and the examples pass the ECS service security group. There is
therefore no configuration in this repository that opens PostgreSQL to the
internet.

**ECS task and execution roles are separate.** The execution role pulls the
image, writes logs and reads only the Secrets Manager ARNs listed in `secrets`.
The task role starts with permission to write its own log stream. Neither role
has a wildcard resource. This is the least-privilege skeleton; the application
adds what it needs.

**CloudFront uses an origin access control, not an origin access identity.**
The bucket policy grants `s3:GetObject` to the CloudFront service only when the
request comes from this distribution's ARN, and all four S3 public access
blocks are enabled. The bucket has no public objects even if an upload is
misconfigured.

**No load balancer module.** An ALB is shared infrastructure with its own
lifecycle, certificate, WAF association and access logs; baking one into
`ecs-service` would make the module harder to reuse behind an API gateway. The
service exposes its security group, and the caller attaches it to the target
group. This is the main deliberate gap in the baseline and the first module a
client would add.

**Alarms are conditional, not nullable.** A CloudWatch alarm with a null
dimension is invalid. The `alarms` module creates the ECS alarms always, the
RDS alarms only when an instance id is passed and the load-balancer alarms only
when both ARN suffixes are supplied. The dev example passes no ALB, so it has no
ALB alarms rather than broken ones.

## Environment differences

`dev` is cheap: two AZs, no NAT gateways, single-AZ `db.t3.micro`, one task and
short retention. `prod` is three AZs, one NAT per AZ, Multi-AZ `db.m6g.large`
with deletion protection, three tasks, 90-day logs and load-balancer alarms.
Both keep the same security posture; only cost and resilience knobs move.

## What is out of scope

Route 53 zones, ACM validation, WAF rules, the ALB itself, autoscaling policies,
VPC endpoints, Secrets Manager rotation and cross-account state. Each would be
its own module, and each is listed in the module READMEs where it affects a
decision. A baseline that pretends to include everything becomes a framework
nobody can review.
