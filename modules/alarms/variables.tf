variable "name_prefix" {
  type        = string
  description = "Prefix for alarm and topic names."
}

variable "ecs_cluster_name" {
  type        = string
  description = "ECS cluster for the CPU and memory alarms."
}

variable "ecs_service_name" {
  type        = string
  description = "ECS service for the CPU and memory alarms."
}

variable "rds_instance_id" {
  type        = string
  description = "RDS resource id. Leave empty when the stack has no database."
  default     = ""
}

variable "alb_arn_suffix" {
  type        = string
  description = "ALB ARN suffix for the 5xx and latency alarms. Empty disables them."
  default     = ""
}

variable "target_group_arn_suffix" {
  type        = string
  description = "Target group ARN suffix for the 5xx and latency alarms."
  default     = ""
}

variable "sns_topic_arn" {
  type        = string
  description = "Existing SNS topic for notifications. Empty creates a topic in this module."
  default     = ""
}

variable "alert_emails" {
  type        = list(string)
  description = "Emails subscribed to the module-created topic. Ignored when sns_topic_arn is set."
  default     = []
}

variable "ecs_cpu_threshold" {
  type        = number
  description = "CPU percentage that triggers the ECS alarm."
  default     = 80
}

variable "ecs_memory_threshold" {
  type        = number
  description = "Memory percentage that triggers the ECS alarm."
  default     = 80
}

variable "rds_cpu_threshold" {
  type        = number
  description = "CPU percentage that triggers the RDS alarm."
  default     = 80
}

variable "rds_free_storage_bytes" {
  type        = number
  description = "Free storage bytes below which the RDS alarm fires (default 5 GiB)."
  default     = 5368709120
}

variable "target_5xx_threshold" {
  type        = number
  description = "Target 5xx count per period that triggers the alarm."
  default     = 10
}

variable "target_latency_ms" {
  type        = number
  description = "p95 target response time in milliseconds."
  default     = 2000
}

variable "period_seconds" {
  type        = number
  description = "CloudWatch period for the alarms."
  default     = 300
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every resource."
  default     = {}
}
