variable "region" {
  type        = string
  description = "AWS region for the development stack."
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
  default     = "dev"
}

variable "owner" {
  type        = string
  description = "Team or person responsible for the stack."
  default     = "platform"
}

variable "container_image" {
  type        = string
  description = "Image for the API service. The dev example expects a public image."
  default     = "public.ecr.aws/nginx/nginx:1.27-alpine"
}

variable "db_password" {
  type        = string
  description = "Database master password. Supply via TF_VAR_db_password, never a committed file."
  sensitive   = true
}

variable "bucket_suffix" {
  type        = string
  description = "Suffix that makes the static-site bucket globally unique."
  default     = "dev"
}

variable "monthly_budget" {
  type        = number
  description = "Monthly budget for the development account, in USD."
  default     = 100
}

variable "alert_emails" {
  type        = list(string)
  description = "Where alarm and budget notifications go."
  default     = []
}
