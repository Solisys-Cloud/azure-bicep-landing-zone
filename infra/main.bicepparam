using 'main.bicep'

// Example values for a development subscription.
// Replace the object IDs with Entra ID groups from your tenant.

param prefix = 'lz'
param location = 'westeurope'

param allowedLocations = [
  'westeurope'
  'northeurope'
]

param tags = {
  Owner: 'platform-team'
  CostCenter: 'IT-CLOUD-001'
  Environment: 'dev'
}

param publicIpEffect = 'Audit'
param policyEnforcementMode = 'Default'

param roleAssignments = [
  // {
  //   principalId: '00000000-0000-0000-0000-000000000000'
  //   principalType: 'Group'
  //   role: 'Reader'
  //   description: 'Auditors'
  // }
  // {
  //   principalId: '00000000-0000-0000-0000-000000000000'
  //   principalType: 'Group'
  //   role: 'LandingZoneOperator'
  //   description: 'Cloud operations team'
  // }
]

param deployPimEligibility = false
param eligibleAssignments = [
  // {
  //   principalId: '00000000-0000-0000-0000-000000000000'
  //   role: 'Owner'
  //   duration: 'P180D'
  // }
]

param budgetAmount = 100
param budgetContactEmails = [
  'cloud-finops@example.com'
]

param logRetentionInDays = 30
