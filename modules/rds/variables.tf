variable "name" {
  type        = string
  description = "Database identifier and resource prefix."
}

variable "engine" {
  type        = string
  description = "Database engine."
  default     = "postgres"
}

variable "engine_version" {
  type        = string
  description = "Engine version. Pin this; auto-minor upgrades are enabled but majors are not."
  default     = "15.7"
}

variable "parameter_group_family" {
  type        = string
  description = "Parameter group family matching the major engine version."
  default     = "postgres15"
}

variable "instance_class" {
  type        = string
  description = "RDS instance class."
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  type        = number
  description = "Allocated storage in GiB."
  default     = 20
}

variable "db_name" {
  type        = string
  description = "Initial database name."
  default     = "app"
}

variable "username" {
  type        = string
  description = "Master username."
  default     = "app"
}

variable "password" {
  type        = string
  description = "Master password. Pass it from a secret store, never from a committed tfvars file."
  sensitive   = true
}

variable "port" {
  type        = number
  description = "Database port."
  default     = 5432
}

variable "vpc_id" {
  type        = string
  description = "VPC for the database security group."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the subnet group."
}

variable "ingress_security_group_ids" {
  type        = list(string)
  description = "Security groups allowed to connect on the database port."
  default     = []
}

variable "backup_retention_period" {
  type        = number
  description = "Days of automated backups to keep."
  default     = 7
}

variable "multi_az" {
  type        = bool
  description = "Create a synchronously replicated standby."
  default     = false
}

variable "deletion_protection" {
  type        = bool
  description = "Block deletion and take a final snapshot. Keep true in production."
  default     = true
}

variable "performance_insights_enabled" {
  type        = bool
  description = "Enable Performance Insights."
  default     = true
}

variable "log_retention_days" {
  type        = number
  description = "Retention for the PostgreSQL log group."
  default     = 30
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every resource."
  default     = {}
}
