output "vpc_id" {
  description = "Production VPC id."
  value       = module.network.vpc_id
}

output "service_security_group_id" {
  description = "Security group for the API tasks."
  value       = module.service.service_security_group_id
}

output "database_endpoint" {
  description = "Production database endpoint."
  value       = module.rds.endpoint
}

output "site_url" {
  description = "Public URL of the production site."
  value       = module.site.site_url
}

output "alarm_topic_arn" {
  description = "SNS topic receiving production alarms."
  value       = module.alarms.sns_topic_arn
}

output "alarm_names" {
  description = "Production alarms created by the alarms module."
  value       = module.alarms.alarm_names
}
