# static-site

S3 + CloudFront for a single-page app or static site. The bucket is private in
four independent ways: public access block, bucket-owner-enforced ownership,
no public ACLs, and a bucket policy that only allows `s3:GetObject` from this
distribution's ARN.

CloudFront uses an Origin Access Control rather than the legacy origin access
identity, TLS is redirected from HTTP, and 403/404 responses serve
`/index.html` so client-side routes work.

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `name` | `string` | required | Project name |
| `bucket_name` | `string` | required | Globally unique bucket |
| `domain_name` | `string` | `""` | Custom domain |
| `certificate_arn` | `string` | `""` | ACM cert in us-east-1 |
| `price_class` | `string` | `PriceClass_100` | CloudFront edge footprint |
| `tags` | `map(string)` | `{}` | Tags |

## Outputs

| Name | Description |
| --- | --- |
| `bucket_name`, `bucket_arn` | Asset bucket |
| `distribution_id` | For cache invalidations |
| `distribution_domain_name` | CloudFront hostname |
| `site_url` | Public URL |
| `origin_access_control_id` | OAC id |

## Notes

Uploading assets and invalidating the distribution are deployment steps, not
Terraform resources: keep the build in CI so an `apply` cannot publish a
half-built site. A custom domain also needs a Route 53 alias and a certificate
in `us-east-1`; those are intentionally not created here.
