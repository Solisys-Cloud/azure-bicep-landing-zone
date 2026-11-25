// FinOps guardrail: monthly subscription budget with actual and forecast alerts.
targetScope = 'subscription'

@description('Budget name.')
param name string

@description('Monthly budget amount in the billing currency.')
@minValue(1)
param amount int

@description('Email addresses notified when thresholds are reached.')
@minLength(1)
param contactEmails array

@description('First day of the budget period, format yyyy-MM-01.')
param startDate string

@description('Actual spend thresholds in percent.')
param actualThresholds array = [
  50
  80
  100
]

@description('Forecasted spend threshold in percent.')
param forecastThreshold int = 100

var actualNotifications = reduce(
  actualThresholds,
  {},
  (acc, threshold) =>
    union(acc, {
      'actual-${threshold}': {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: threshold
        thresholdType: 'Actual'
        contactEmails: contactEmails
      }
    })
)

resource budget 'Microsoft.Consumption/budgets@2026-06-01' = {
  name: name
  properties: {
    category: 'Cost'
    amount: amount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: startDate
    }
    notifications: union(actualNotifications, {
      'forecast-${forecastThreshold}': {
        enabled: true
        operator: 'GreaterThan'
        threshold: forecastThreshold
        thresholdType: 'Forecasted'
        contactEmails: contactEmails
      }
    })
  }
}

output budgetId string = budget.id
