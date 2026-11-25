// Governance baseline: custom policy definition, initiative and subscription assignment.
targetScope = 'subscription'

@description('Short prefix used in resource names.')
param prefix string

@description('Location of the policy assignment managed identity.')
param location string

@description('Azure regions allowed for resources and resource groups.')
param allowedLocations array

@description('Tag names that must exist on resource groups and are inherited by resources.')
param requiredTagNames array

@description('Effect of the public IP restriction.')
@allowed([
  'Audit'
  'Deny'
  'Disabled'
])
param publicIpEffect string = 'Audit'

@description('Enforcement mode of the assignment. DoNotEnforce evaluates compliance without blocking deployments.')
@allowed([
  'Default'
  'DoNotEnforce'
])
param enforcementMode string = 'Default'

// Built-in policy definitions are referenced with tenantResourceId (IDs are global and stable).

// Tag Contributor, required by the Modify effect to remediate tags.
var tagContributorRoleId = '4a9ae827-6dc8-4573-8ac7-8239d42aa03f'

resource denyPublicIp 'Microsoft.Authorization/policyDefinitions@2025-03-01' = {
  name: '${prefix}-restrict-public-ip'
  properties: {
    displayName: 'Restrict public IP addresses'
    description: 'Audits or denies the creation of public IP addresses outside approved hub components.'
    policyType: 'Custom'
    mode: 'All'
    metadata: {
      category: 'Network'
      version: '1.0.0'
    }
    parameters: {
      effect: {
        type: 'String'
        allowedValues: [
          'Audit'
          'Deny'
          'Disabled'
        ]
        defaultValue: 'Audit'
      }
    }
    policyRule: {
      if: {
        field: 'type'
        equals: 'Microsoft.Network/publicIPAddresses'
      }
      then: {
        effect: '[parameters(\'effect\')]'
      }
    }
  }
}

var tagDefinitions = [
  for tagName in requiredTagNames: [
    {
      policyDefinitionReferenceId: 'require-tag-${toLower(tagName)}'
      policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', '96670d01-0a4d-4649-9c89-2d3abc0a5025')
      parameters: {
        tagName: {
          value: tagName
        }
      }
    }
    {
      policyDefinitionReferenceId: 'inherit-tag-${toLower(tagName)}'
      policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', 'ea3f2387-9b95-492a-a190-fcdc54f7b070')
      parameters: {
        tagName: {
          value: tagName
        }
      }
    }
  ]
]

resource baseline 'Microsoft.Authorization/policySetDefinitions@2025-03-01' = {
  name: '${prefix}-landing-zone-baseline'
  properties: {
    displayName: 'Landing Zone Baseline'
    description: 'Data residency, tagging and network exposure guardrails for landing zone subscriptions.'
    policyType: 'Custom'
    metadata: {
      category: 'Landing Zone'
      version: '1.0.0'
    }
    parameters: {
      listOfAllowedLocations: {
        type: 'Array'
        metadata: {
          displayName: 'Allowed locations'
          strongType: 'location'
        }
      }
      publicIpEffect: {
        type: 'String'
        allowedValues: [
          'Audit'
          'Deny'
          'Disabled'
        ]
        defaultValue: 'Audit'
      }
    }
    policyDefinitions: concat(
      [
        {
          policyDefinitionReferenceId: 'allowed-locations'
          policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', 'e56962a6-4747-49cd-b67b-bf8b01975c4c')
          parameters: {
            listOfAllowedLocations: {
              value: '[parameters(\'listOfAllowedLocations\')]'
            }
          }
        }
        {
          policyDefinitionReferenceId: 'allowed-locations-resource-groups'
          policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', 'e765b5de-1225-4ba3-bd56-1ac6695af988')
          parameters: {
            listOfAllowedLocations: {
              value: '[parameters(\'listOfAllowedLocations\')]'
            }
          }
        }
        {
          policyDefinitionReferenceId: 'restrict-public-ip'
          policyDefinitionId: denyPublicIp.id
          parameters: {
            effect: {
              value: '[parameters(\'publicIpEffect\')]'
            }
          }
        }
      ],
      flatten(tagDefinitions)
    )
  }
}

resource assignment 'Microsoft.Authorization/policyAssignments@2025-03-01' = {
  name: '${prefix}-baseline'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'Landing Zone Baseline'
    description: 'Baseline guardrails assigned at subscription scope.'
    policyDefinitionId: baseline.id
    enforcementMode: enforcementMode
    parameters: {
      listOfAllowedLocations: {
        value: allowedLocations
      }
      publicIpEffect: {
        value: publicIpEffect
      }
    }
    nonComplianceMessages: [
      {
        message: 'This deployment does not meet the landing zone baseline. Check region, tags and public IP usage.'
      }
    ]
  }
}

resource remediationRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, assignment.id, tagContributorRoleId)
  properties: {
    principalId: assignment.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', tagContributorRoleId)
    description: 'Allows the baseline assignment to remediate inherited tags.'
  }
}

output initiativeId string = baseline.id
output assignmentId string = assignment.id
