# budget

A monthly cost budget with forecasted-spend notifications. Each email address
is subscribed at each threshold, so `["ops@example.com"]` with the default
thresholds produces three notifications: 50%, 80% and 100% of the forecast.

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `name` | `string` | required | Budget name |
| `limit_amount` | `number` | required | Spend limit |
| `currency` | `string` | `USD` | Limit currency |
| `time_unit` | `string` | `MONTHLY` | Budget period |
| `notification_emails` | `list(string)` | `[]` | Subscribers |
| `thresholds` | `list(number)` | `[50, 80, 100]` | Forecast percentages |
| `tags` | `map(string)` | `{}` | Tags |

## Outputs

| Name | Description |
| --- | --- |
| `budget_name`, `budget_id` | Budget identifiers |
| `notification_count` | Number of notifications |

## Notes

The budget is account-wide by default and does not distinguish environments.
In a shared account, add a `cost_filter` for the environment tag; the module
leaves it out because a filter with the wrong tag silently reports on nothing.
Forecasted notifications can fire before actual spend reaches the threshold,
which is intentional: the point is warning, not accounting.
