output "vpc_id" {
  description = "ID of the created VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs, ordered by availability zone."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs, ordered by availability zone."
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ids" {
  description = "NAT gateway IDs (empty when NAT is disabled)."
  value       = aws_nat_gateway.this[*].id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}
