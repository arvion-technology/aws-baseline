variable "region" {
  type        = string
  description = "AWS region for the production stack."
  default     = "ap-south-1"
}

variable "project" {
  type        = string
  description = "Project slug used in resource names."
  default     = "arvion-labs"
}

variable "environment" {
  type        = string
  description = "Environment name."
  default     = "prod"
}

variable "owner" {
  type        = string
  description = "Team responsible for the stack."
  default     = "platform"
}

variable "cost_center" {
  type        = string
  description = "Cost center tag used by budgets and reporting."
  default     = "engineering"
}

variable "container_image" {
  type        = string
  description = "Image for the API service, pinned by digest in real use."
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class for production."
  default     = "db.m6g.large"
}

variable "db_password" {
  type        = string
  description = "Database master password. Supply via TF_VAR_db_password from the secret store."
  sensitive   = true
}

variable "bucket_suffix" {
  type        = string
  description = "Suffix that makes the static-site bucket globally unique."
  default     = "prod"
}

variable "site_domain" {
  type        = string
  description = "Custom domain for the site, or empty to use the CloudFront hostname."
  default     = ""
}

variable "site_certificate_arn" {
  type        = string
  description = "ACM certificate ARN in us-east-1 for the custom domain."
  default     = ""
}

variable "alb_arn_suffix" {
  type        = string
  description = "ALB ARN suffix for the load-balancer alarms. Empty disables them."
  default     = ""
}

variable "target_group_arn_suffix" {
  type        = string
  description = "Target group ARN suffix for the load-balancer alarms."
  default     = ""
}

variable "monthly_budget" {
  type        = number
  description = "Monthly production budget in USD."
  default     = 1500
}

variable "alert_emails" {
  type        = list(string)
  description = "Where alarm and budget notifications go."
}
