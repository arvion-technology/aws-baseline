output "sns_topic_arn" {
  description = "Topic that receives alarm notifications."
  value       = local.topic_arn
}

output "alarm_names" {
  description = "Names of the alarms created by the module."
  value = compact([
    aws_cloudwatch_metric_alarm.ecs_cpu.alarm_name,
    aws_cloudwatch_metric_alarm.ecs_memory.alarm_name,
    local.rds_enabled ? aws_cloudwatch_metric_alarm.rds_cpu[0].alarm_name : "",
    local.rds_enabled ? aws_cloudwatch_metric_alarm.rds_free_storage[0].alarm_name : "",
    local.alb_enabled ? aws_cloudwatch_metric_alarm.target_5xx[0].alarm_name : "",
    local.alb_enabled ? aws_cloudwatch_metric_alarm.target_latency[0].alarm_name : "",
  ])
}
