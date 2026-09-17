output "budget_name" {
  description = "Name of the budget."
  value       = aws_budgets_budget.this.name
}

output "budget_id" {
  description = "Budget id used by the Budgets API."
  value       = aws_budgets_budget.this.id
}

output "notification_count" {
  description = "Number of forecasted-spend notifications configured."
  value       = length(var.notification_emails) * length(var.thresholds)
}
