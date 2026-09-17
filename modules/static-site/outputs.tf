output "bucket_name" {
  description = "Name of the asset bucket."
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "ARN of the asset bucket."
  value       = aws_s3_bucket.this.arn
}

output "distribution_id" {
  description = "CloudFront distribution id, used for invalidations."
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_domain_name" {
  description = "CloudFront domain name."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "site_url" {
  description = "Public URL of the site (custom domain when configured)."
  value       = var.domain_name == "" ? "https://${aws_cloudfront_distribution.this.domain_name}" : "https://${var.domain_name}"
}

output "origin_access_control_id" {
  description = "Origin access control id tying CloudFront to the bucket policy."
  value       = aws_cloudfront_origin_access_control.this.id
}
