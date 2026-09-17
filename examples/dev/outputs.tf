output "vpc_id" {
  description = "Development VPC id."
  value       = module.network.vpc_id
}

output "service_security_group_id" {
  description = "Security group for the API tasks. Attach it to the load balancer."
  value       = module.service.service_security_group_id
}

output "database_endpoint" {
  description = "Development database endpoint."
  value       = module.rds.endpoint
  sensitive   = false
}

output "site_url" {
  description = "CloudFront URL of the static site."
  value       = module.site.site_url
}

output "alarm_topic_arn" {
  description = "SNS topic receiving development alarms."
  value       = module.alarms.sns_topic_arn
}

output "budget_name" {
  description = "Name of the monthly budget."
  value       = module.budget.budget_name
}
