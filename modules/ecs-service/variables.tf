variable "cluster_name" {
  type        = string
  description = "Name of the ECS cluster (created if it does not exist)."
}

variable "service_name" {
  type        = string
  description = "Service name, also used for IAM roles and the log group."
}

variable "container_image" {
  type        = string
  description = "Fully qualified image reference, ideally pinned by digest."
}

variable "container_port" {
  type        = number
  description = "Port the application listens on inside the container."
  default     = 8080
}

variable "health_check_path" {
  type        = string
  description = "HTTP path the container health check calls."
  default     = "/health"
}

variable "cpu" {
  type        = string
  description = "Fargate CPU units (256, 512, 1024, 2048, 4096)."
  default     = "512"
}

variable "memory" {
  type        = string
  description = "Fargate memory in MiB, compatible with the chosen CPU."
  default     = "1024"
}

variable "desired_count" {
  type        = number
  description = "Initial task count. Autoscaling is left to the caller."
  default     = 2
}

variable "vpc_id" {
  type        = string
  description = "VPC the service security group belongs to."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnets for the Fargate tasks."
}

variable "environment" {
  type        = map(string)
  description = "Plain-text environment variables passed to the container."
  default     = {}
}

variable "secrets" {
  type        = map(string)
  description = "Environment variable name to Secrets Manager ARN. The execution role can read exactly these."
  default     = {}
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch Logs retention for the service log group."
  default     = 30
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every resource."
  default     = {}
}
