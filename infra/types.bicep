// Shared user-defined types for the landing zone deployment.

@export()
@description('Mandatory governance tags applied to every resource group.')
type governanceTags = {
  @description('Accountable team or person.')
  Owner: string

  @description('Cost center used for chargeback and Cost Management views.')
  CostCenter: string

  @description('Deployment environment.')
  Environment: ('dev' | 'test' | 'prod')

  @description('Optional additional tags.')
  *: string
}

@export()
@description('Role assignment for an Entra ID group, user or service principal.')
type roleAssignmentType = {
  @description('Object ID of the Entra ID principal.')
  principalId: string

  @description('Principal type.')
  principalType: ('Group' | 'User' | 'ServicePrincipal')

  @description('Role name from the builtInRoles map, or LandingZoneOperator for the custom role.')
  role: ('Reader' | 'Contributor' | 'NetworkContributor' | 'CostManagementReader' | 'MonitoringReader' | 'LandingZoneOperator')

  @description('Optional description shown on the assignment.')
  description: string?
}

@export()
@description('PIM eligible assignment for a privileged role.')
type eligibleAssignmentType = {
  @description('Object ID of the Entra ID group or user.')
  principalId: string

  @description('Built-in role to make eligible.')
  role: ('Owner' | 'Contributor' | 'UserAccessAdministrator')

  @description('ISO 8601 duration of the eligibility, for example P180D.')
  duration: string
}
