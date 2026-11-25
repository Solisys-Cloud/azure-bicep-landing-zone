// Delegated administration: custom operator role and least-privilege assignments.
targetScope = 'subscription'

import { roleAssignmentType } from '../../types.bicep'

@description('Short prefix used in resource names.')
param prefix string

@description('Role assignments to create at subscription scope.')
param roleAssignments roleAssignmentType[]

var builtInRoles = {
  Reader: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
  Contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  NetworkContributor: '4d97b98b-1d4f-4787-a291-c67834d212e7'
  CostManagementReader: '72fafb9e-0641-4937-9268-a91bfd8191a3'
  MonitoringReader: '43d0d8ad-25c7-4714-9337-8ba259a9fe05'
}

resource operatorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(subscription().id, '${prefix}-landing-zone-operator')
  properties: {
    roleName: '${toUpper(prefix)} Landing Zone Operator'
    description: 'Day-to-day operations without the right to change access, policies or network topology.'
    type: 'CustomRole'
    assignableScopes: [
      subscription().id
    ]
    permissions: [
      {
        actions: [
          '*/read'
          'Microsoft.Compute/virtualMachines/start/action'
          'Microsoft.Compute/virtualMachines/restart/action'
          'Microsoft.Compute/virtualMachines/deallocate/action'
          'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems/backup/action'
          'Microsoft.Insights/alertRules/*'
          'Microsoft.Resources/deployments/*'
          'Microsoft.Support/*'
        ]
        notActions: [
          'Microsoft.Authorization/*/write'
          'Microsoft.Authorization/*/delete'
          'Microsoft.Network/virtualNetworks/write'
          'Microsoft.Network/virtualNetworks/delete'
        ]
        dataActions: []
        notDataActions: []
      }
    ]
  }
}

resource assignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for item in roleAssignments: {
    name: guid(subscription().id, item.principalId, item.role)
    properties: {
      principalId: item.principalId
      principalType: item.principalType
      roleDefinitionId: item.role == 'LandingZoneOperator'
        ? operatorRole.id
        : subscriptionResourceId('Microsoft.Authorization/roleDefinitions', builtInRoles[item.role])
      description: item.?description ?? 'Managed by the landing zone deployment.'
    }
  }
]

output operatorRoleId string = operatorRole.id
