locals {
  create_topic = var.sns_topic_arn == ""
  topic_arn    = local.create_topic ? aws_sns_topic.this[0].arn : var.sns_topic_arn
  rds_enabled  = var.rds_instance_id != ""
  alb_enabled  = var.alb_arn_suffix != "" && var.target_group_arn_suffix != ""
}

resource "aws_sns_topic" "this" {
  count = local.create_topic ? 1 : 0

  name = "${var.name_prefix}-alarms"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  count = local.create_topic ? length(var.alert_emails) : 0

  topic_arn = aws_sns_topic.this[0].arn
  protocol  = "email"
  endpoint  = var.alert_emails[count.index]
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  alarm_name          = "${var.name_prefix}-ecs-cpu-high"
  alarm_description   = "ECS service CPU above ${var.ecs_cpu_threshold}% for 15 minutes."
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.ecs_cpu_threshold
  evaluation_periods  = 3
  period              = var.period_seconds
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = [local.topic_arn]
  ok_actions    = [local.topic_arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory" {
  alarm_name          = "${var.name_prefix}-ecs-memory-high"
  alarm_description   = "ECS service memory above ${var.ecs_memory_threshold}% for 15 minutes."
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  statistic           = "Average"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.ecs_memory_threshold
  evaluation_periods  = 3
  period              = var.period_seconds
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = [local.topic_arn]
  ok_actions    = [local.topic_arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  count = local.rds_enabled ? 1 : 0

  alarm_name          = "${var.name_prefix}-rds-cpu-high"
  alarm_description   = "RDS CPU above ${var.rds_cpu_threshold}% for 15 minutes."
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.rds_cpu_threshold
  evaluation_periods  = 3
  period              = var.period_seconds
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_actions = [local.topic_arn]
  ok_actions    = [local.topic_arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  count = local.rds_enabled ? 1 : 0

  alarm_name          = "${var.name_prefix}-rds-free-storage-low"
  alarm_description   = "RDS free storage below ${var.rds_free_storage_bytes} bytes."
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  statistic           = "Average"
  comparison_operator = "LessThanThreshold"
  threshold           = var.rds_free_storage_bytes
  evaluation_periods  = 2
  period              = var.period_seconds
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_actions = [local.topic_arn]
  ok_actions    = [local.topic_arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "target_5xx" {
  count = local.alb_enabled ? 1 : 0

  alarm_name          = "${var.name_prefix}-target-5xx"
  alarm_description   = "More than ${var.target_5xx_threshold} target 5xx responses in 5 minutes."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  statistic           = "Sum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.target_5xx_threshold
  evaluation_periods  = 1
  period              = var.period_seconds
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  alarm_actions = [local.topic_arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "target_latency" {
  count = local.alb_enabled ? 1 : 0

  alarm_name          = "${var.name_prefix}-target-latency"
  alarm_description   = "p95 target response time above ${var.target_latency_ms} ms."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  extended_statistic  = "p95"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.target_latency_ms / 1000
  evaluation_periods  = 3
  period              = var.period_seconds
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  alarm_actions = [local.topic_arn]

  tags = var.tags
}
