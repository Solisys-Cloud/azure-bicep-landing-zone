// Just-in-time access: PIM eligible assignments for privileged roles.
// Requires Microsoft Entra ID P2 or Entra ID Governance licensing.
targetScope = 'subscription'

import { eligibleAssignmentType } from '../../types.bicep'

@description('Eligible assignments to create.')
param eligibleAssignments eligibleAssignmentType[]

@description('Start of the eligibility window. Defaults to deployment time.')
param startDateTime string = utcNow()

var privilegedRoles = {
  Owner: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  Contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  UserAccessAdministrator: '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9'
}

resource eligibility 'Microsoft.Authorization/roleEligibilityScheduleRequests@2020-10-01' = [
  for item in eligibleAssignments: {
    name: guid(subscription().id, item.principalId, item.role, 'eligible')
    properties: {
      principalId: item.principalId
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', privilegedRoles[item.role])
      requestType: 'AdminAssign'
      justification: 'Just-in-time access managed by the landing zone deployment.'
      scheduleInfo: {
        startDateTime: startDateTime
        expiration: {
          type: 'AfterDuration'
          duration: item.duration
        }
      }
    }
  }
]
