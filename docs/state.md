# State

Terraform state is the most sensitive artifact in an AWS account: it contains
resource attributes, and a database resource can contain its password. It
should never live on a laptop that can be lost, and two engineers should never
apply the same state at the same time.

## Layout

One state file per account and environment:

```text
s3://<org>-terraform-state/
├── dev/terraform.tfstate
├── prod/terraform.tfstate
└── shared/terraform.tfstate
```

The bucket is created once, outside this repository, with:

- versioning enabled (so a bad apply can be inspected and rolled back)
- default encryption (SSE-S3 or SSE-KMS)
- public access blocked
- a bucket policy that only the deployment role can write

The examples keep the `backend "s3"` block commented out. Pass the values with
`-backend-config` from CI so a bucket name is not baked into a module a client
might reuse:

```bash
terraform init \
  -backend-config="bucket=arvion-terraform-state" \
  -backend-config="key=prod/terraform.tfstate" \
  -backend-config="region=ap-south-1" \
  -backend-config="use_lockfile=true"
```

`use_lockfile` is the S3-native lock added in Terraform 1.10; on older versions
use a DynamoDB table with `dynamodb_table = "<name>"` instead. Pick one, not
both.

## Environments

`examples/dev` and `examples/prod` are separate root modules with separate state.
They share module source, not state. Promoting a change means opening a pull
request that touches both, applying to dev, watching the alarms for a day, then
applying the same commit to prod. There is no `terraform workspace` shortcut:
workspace state is easy to apply to the wrong environment when the workspace
name comes from a shell variable.

## Secrets

The database password is an input, marked `sensitive`. It must come from the CI
secret store or Secrets Manager at plan time:

```bash
export TF_VAR_db_password="$(aws secretsmanager get-secret-value \
  --secret-id prod/db-master --query SecretString --output text)"
```

`terraform plan` and `terraform apply` will still write the value into state.
That is another reason the state bucket is private, versioned and encrypted.
Rotating the password is a Secrets Manager concern, not something this baseline
automates.

## Drift

The `alarms` module is a tripwire for drift in the resources it can observe, but
it does not detect configuration drift. Run `terraform plan` on a schedule from
CI and alert when it is not empty; that is the only reliable drift check without
an external tool.
