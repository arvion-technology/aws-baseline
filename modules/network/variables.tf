variable "name" {
  type        = string
  description = "Prefix used on every network resource."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,24}$", var.name))
    error_message = "Use 2-25 lower-case characters starting with a letter."
  }
}

variable "cidr" {
  type        = string
  description = "VPC CIDR block."
  default     = "10.0.0.0/16"
}

variable "az_count" {
  type        = number
  description = "Number of availability zones to spread subnets across."
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "Use two or three availability zones."
  }
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR for each public subnet, one per AZ."
  default     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR for each private subnet, one per AZ."
  default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Create one NAT gateway per AZ so private subnets can reach the internet."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every resource."
  default     = {}
}
