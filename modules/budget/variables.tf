variable "name" {
  type        = string
  description = "Budget name shown in the AWS console and Cost Explorer."
}

variable "limit_amount" {
  type        = number
  description = "Monthly (or per time_unit) spend limit."
}

variable "currency" {
  type        = string
  description = "Currency for the limit. AWS budgets do not convert currencies."
  default     = "USD"
}

variable "time_unit" {
  type        = string
  description = "DAILY, MONTHLY, QUARTERLY or ANNUALLY."
  default     = "MONTHLY"
}

variable "notification_emails" {
  type        = list(string)
  description = "Addresses that receive forecasted-budget notifications."
  default     = []
}

variable "thresholds" {
  type        = list(number)
  description = "Forecasted spend percentages that trigger a notification."
  default     = [50, 80, 100]
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the budget."
  default     = {}
}
