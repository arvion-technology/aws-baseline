output "endpoint" {
  description = "Connection endpoint (host:port) of the database."
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "Hostname of the database."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Port the database listens on."
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "Initial database name."
  value       = aws_db_instance.this.db_name
}

output "security_group_id" {
  description = "Security group attached to the database."
  value       = aws_security_group.database.id
}

output "resource_id" {
  description = "RDS resource id, used by CloudWatch dimensions in the alarms module."
  value       = aws_db_instance.this.resource_id
}
