
// Parameters
@description('Location where resources will be deployed. Defaults to resource group location')
param location string = resourceGroup().location

@description('Cost Centre tag that will be applied to all resources in this deployment')
param cost_centre_tag string

@description('System Owner tag that will be applied to all resources in this deployment')
param owner_tag string

@description('Subject Matter Expert (SME) tag that will be applied to all resources in this deployment')
param sme_tag string

@description('Key Vault name')
param keyvault_name string

@description('Purview Account name')
param purview_account_name string

@description('Resource group of Purview Account')
param purviewrg string

// Variables
var suffix = uniqueString(resourceGroup().id)
var keyvault_uniquename = '${keyvault_name}-${suffix}'


// Create Key Vault
resource keyvault 'Microsoft.KeyVault/vaults@2023-07-01' ={
  name: keyvault_uniquename
  location: location
  tags: {
    CostCentre: cost_centre_tag
    Owner: owner_tag
    SME: sme_tag
  }
  properties:{
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    // Default Access Policies. Replace the ObjectID's with your user/group id
    accessPolicies:[
      { tenantId: subscription().tenantId
        objectId: '4fd294da-9b64-454e-94dd-861a0a9133db' // Replace this with your user/group ObjectID
        permissions: {secrets:['list','get','set']}
      }
      { tenantId: subscription().tenantId
        objectId: '78a10848-91aa-43a4-b380-01e883b7233e' // Replace this with your user/group ObjectID
        permissions: {secrets:['list','get','set']}
      }
      { tenantId: subscription().tenantId
        objectId: '745d3c96-f106-49ee-b7fc-dfb936835a72' // Replace this with your user/group ObjectID
        permissions: {secrets:['list','get']}
      }
    ]
  }
}

// Create Key Vault Access Policies for Purview
resource existing_purview_account 'Microsoft.Purview/accounts@2021-07-01' existing = {
    name: purview_account_name
    scope: resourceGroup(purviewrg)
  }
  
resource this_keyvault_accesspolicy 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  name: 'add'
  parent: keyvault
  properties: {
    accessPolicies: [
      { tenantId: subscription().tenantId
        objectId: existing_purview_account.identity.principalId
        permissions: { secrets:  ['list','get']}

      }
    ]
  }
}

output keyvault_name string = keyvault.name
