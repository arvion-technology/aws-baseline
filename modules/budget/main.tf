resource "aws_budgets_budget" "this" {
  name         = var.name
  budget_type  = "COST"
  limit_amount = var.limit_amount
  limit_unit   = var.currency
  time_unit    = var.time_unit

  dynamic "notification" {
    for_each = {
      for pair in setproduct(var.notification_emails, var.thresholds) :
      "${pair[0]}-${pair[1]}" => { email = pair[0], threshold = pair[1] }
    }

    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value.threshold
      threshold_type             = "PERCENTAGE"
      notification_type          = "FORECASTED"
      subscriber_email_addresses = [notification.value.email]
    }
  }

  tags = var.tags
}
