// Sends the subscription Activity Log to the central workspace.
targetScope = 'subscription'

@description('Resource ID of the Log Analytics workspace.')
param workspaceId string

var categories = [
  'Administrative'
  'Security'
  'ServiceHealth'
  'Alert'
  'Recommendation'
  'Policy'
  'Autoscale'
  'ResourceHealth'
]

// Subscription-level diagnostic settings require a preview API version.
#disable-next-line use-recent-api-versions
resource activityLog 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'activity-log-to-law'
  properties: {
    workspaceId: workspaceId
    logs: [
      for category in categories: {
        category: category
        enabled: true
      }
    ]
  }
}
