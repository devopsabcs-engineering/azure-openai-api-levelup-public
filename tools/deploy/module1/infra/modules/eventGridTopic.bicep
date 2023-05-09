@description('The unique name for the Azure Storage Account.')
param storageAccountName string = 'opai${uniqueString(resourceGroup().id)}'

@description('The unique name for the Azure Function App.')
param functionAppName string = 'xact-classifier-openai-${uniqueString(resourceGroup().id)}'

// Optional params
@description('The region to deploy the cluster. By default this will use the same region as the resource group.')
param location string = resourceGroup().location

//event system grid topic
param systemTopics_classification_name string = 'classification'
//param storageAccounts_opaiqa6l5q4q6gpsm_externalid string = '/subscriptions/141c10f3-78d9-48dc-b701-d2837ccf2067/resourceGroups/rg-azure-openai-test-002/providers/Microsoft.Storage/storageAccounts/opaiqa6l5q4q6gpsm'
//param sites_xact_classifier_openai_qa6l5q4q6gpsm_externalid string = '/subscriptions/141c10f3-78d9-48dc-b701-d2837ccf2067/resourceGroups/rg-azure-openai-test-002/providers/Microsoft.Web/sites/xact-classifier-openai-qa6l5q4q6gpsm'

//Create a reference to the existing storage account
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

//Create a reference to the existing function app
resource functionApp 'Microsoft.Web/sites@2022-03-01' existing = {
  name: functionAppName
}

resource systemTopics_classification_name_resource 'Microsoft.EventGrid/systemTopics@2022-06-15' = {
  name: systemTopics_classification_name
  location: location // 'eastus'
  properties: {
    source: storageAccount.id // storageAccounts_opaiqa6l5q4q6gpsm_externalid
    topicType: 'Microsoft.Storage.StorageAccounts'
  }
}

resource systemTopics_classification_name_systemTopics_classification_name 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2022-06-15' = {
  parent: systemTopics_classification_name_resource
  name: systemTopics_classification_name
  properties: {
    destination: {
      properties: {
        resourceId: '${functionApp.id}/functions/TransactionClassifier'
        maxEventsPerBatch: 1
        preferredBatchSizeInKilobytes: 64
      }
      endpointType: 'AzureFunction'
    }
    filter: {
      includedEventTypes: [
        'Microsoft.Storage.BlobCreated'
      ]
      enableAdvancedFilteringOnArrays: true
    }
    labels: []
    eventDeliverySchema: 'EventGridSchema'
    retryPolicy: {
      maxDeliveryAttempts: 30
      eventTimeToLiveInMinutes: 1440
    }
  }
}
