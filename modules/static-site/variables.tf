variable "name" {
  type        = string
  description = "Project name used in the CloudFront resources."
}

variable "bucket_name" {
  type        = string
  description = "Globally unique bucket name for the site assets."
}

variable "domain_name" {
  type        = string
  description = "Optional custom domain. Must exist in Route 53 and have a certificate."
  default     = ""
}

variable "certificate_arn" {
  type        = string
  description = "ACM certificate ARN in us-east-1 for the custom domain (CloudFront requirement)."
  default     = ""
}

variable "price_class" {
  type        = string
  description = "CloudFront price class. PriceClass_100 is the cheapest edge footprint."
  default     = "PriceClass_100"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every resource."
  default     = {}
}
