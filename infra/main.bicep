// Azure Landing Zone with Bicep - subscription-scope entry point.
targetScope = 'subscription'

metadata name = 'Azure Landing Zone with Bicep'
metadata description = 'Governance, delegated administration, cost guardrails and central logging for an Azure subscription.'
metadata author = 'Olivier Lumeau'

import { governanceTags, roleAssignmentType, eligibleAssignmentType } from 'types.bicep'

@description('Short prefix used in resource names, 2 to 6 lowercase characters.')
@minLength(2)
@maxLength(6)
param prefix string

@description('Primary Azure region.')
param location string = 'westeurope'

@description('Regions allowed by policy. Include the paired region for disaster recovery.')
param allowedLocations array = [
  'westeurope'
  'northeurope'
]

@description('Mandatory governance tags.')
param tags governanceTags

@description('Effect of the public IP restriction policy.')
@allowed([
  'Audit'
  'Deny'
  'Disabled'
])
param publicIpEffect string = 'Audit'

@description('Policy enforcement mode. Start with DoNotEnforce on existing subscriptions.')
@allowed([
  'Default'
  'DoNotEnforce'
])
param policyEnforcementMode string = 'Default'

@description('Least-privilege role assignments for Entra ID groups.')
param roleAssignments roleAssignmentType[] = []

@description('Deploy PIM eligible assignments. Requires Entra ID P2.')
param deployPimEligibility bool = false

@description('PIM eligible assignments for privileged roles.')
param eligibleAssignments eligibleAssignmentType[] = []

@description('Monthly budget amount in the billing currency.')
param budgetAmount int = 100

@description('Budget alert recipients.')
param budgetContactEmails array

@description('Budget start date. Defaults to the first day of the current month.')
param budgetStartDate string = '${utcNow('yyyy-MM')}-01'

@description('Log Analytics retention in days.')
param logRetentionInDays int = 30

var env = tags.Environment
var names = {
  managementRg: 'rg-${prefix}-management-${env}'
  workspace: 'law-${prefix}-platform-${env}'
  budget: 'budget-${prefix}-subscription-${env}'
}

resource managementRg 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: names.managementRg
  location: location
  tags: tags
}

module workspace 'modules/monitoring/log-analytics.bicep' = {
  name: 'lz-workspace'
  scope: managementRg
  params: {
    name: names.workspace
    location: location
    retentionInDays: logRetentionInDays
    tags: tags
  }
}

module activityLog 'modules/monitoring/activity-log.bicep' = {
  name: 'lz-activity-log'
  params: {
    workspaceId: workspace.outputs.id
  }
}

module policy 'modules/governance/policy-baseline.bicep' = {
  name: 'lz-policy-baseline'
  params: {
    prefix: prefix
    location: location
    allowedLocations: allowedLocations
    requiredTagNames: [
      'Owner'
      'CostCenter'
      'Environment'
    ]
    publicIpEffect: publicIpEffect
    enforcementMode: policyEnforcementMode
  }
}

module rbac 'modules/identity/rbac.bicep' = {
  name: 'lz-rbac'
  params: {
    prefix: prefix
    roleAssignments: roleAssignments
  }
}

module pim 'modules/identity/pim-eligibility.bicep' = if (deployPimEligibility) {
  name: 'lz-pim'
  params: {
    eligibleAssignments: eligibleAssignments
  }
}

module budget 'modules/cost/budget.bicep' = {
  name: 'lz-budget'
  params: {
    name: names.budget
    amount: budgetAmount
    contactEmails: budgetContactEmails
    startDate: budgetStartDate
  }
}

output managementResourceGroup string = managementRg.name
output workspaceId string = workspace.outputs.id
output policyAssignmentId string = policy.outputs.assignmentId
output operatorRoleId string = rbac.outputs.operatorRoleId
output budgetId string = budget.outputs.budgetId
