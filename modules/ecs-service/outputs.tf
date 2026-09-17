output "cluster_arn" {
  description = "ARN of the ECS cluster."
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster."
  value       = aws_ecs_cluster.this.name
}

output "service_name" {
  description = "Name of the ECS service."
  value       = aws_ecs_service.this.name
}

output "service_security_group_id" {
  description = "Security group attached to the tasks. Allow ingress to this from the load balancer."
  value       = aws_security_group.service.id
}

output "task_definition_arn" {
  description = "ARN of the current task definition."
  value       = aws_ecs_task_definition.this.arn
}

output "log_group_name" {
  description = "CloudWatch log group for the service."
  value       = aws_cloudwatch_log_group.this.name
}
