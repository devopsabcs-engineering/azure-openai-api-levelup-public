---
title: Lab
parent:  Module 1 - Transaction Classification Application
has_children: false
nav_order: 2
---

# Module 1: Lab - Transaction Classification Application

In this lab, you will create a transaction classification application that uses the Azure OpenAI API and other Azure services to classify a public dataset of transactions into a number of categories that we have predefined. These approaches should be replicable to any multiclass classificaiton use case where we are trying to fit transactional data into predefined categories, and by the end of running through this you should have an approach for dealing with unlabelled datasets.

For this workshop, we will be using GitHub Actions using OpenID Connect and Infrastructure-as-Code (IaC) using Bicep, to derive following benefits:

* Infrastructure-as-Code (IaC) - Infrastructure is defined as code, and can be version controlled and reviewed.
* OpenID Connect - OpenID Connect is an authentication protocol that allows you to connect securely to Azure resources using your GitHub account.
* GitHub Actions - GitHub Actions is a feature of GitHub that allows you to automate your software development workflows.

## Steps for Deploying the infrastructure

1. Creating an Azure Resource Group
1. Creating Azure OpenAI API resource and deployment of `text-davinci-003` model
1. Configuring OpenID Connect in Azure.
1. Setting Github Actions secrets
1. Enabling the GitHub Actions workflow
1. Creation of Azure Storage Account and Azure Function App
1. Deploying the Azure Function App code
1. Creating and configuring Event Grid Subscription

### Creating an Azure Resource Group

```bash
az login
```

   > [!NOTE]
   > if you are using a non-Microsoft account (e.g. FDPO account), and if are running CodeSpaces in the browser, you may receive an error with message `localhost refused to connect` after logging in. 
   > ![localhost refused to connect](../../assets/images/module1/screenshot-localhost.png)
   > If so:
   > 
   > 1. Copy the URL.
   > 1. Run `curl '<pasted url>'` (URL in quotes) in a new Visual Studio Code terminal.
   >
   > ![curl localhost](../../assets/images/module1/curl-localhost.png)
   > 1. In the original terminal, the login should now succeed.

Set appropriate Subscription Id

```bash
az account set -s <your-subscription-id>
```

Ensure correct Subscription Id is set

```bash
az account show
```

Create Azure Resource Group

```bash
export resourceGroupName="openai-levelup-rg"
export location="eastus"
az group create --name $resourceGroupName --location $location
```

### Creating Azure OpenAI API resource and deployment of `text-davinci-003` model

If you have not already created an Azure OpenAI API resource and deployed the `text-davinci-003` model, you can follow the instructions [here](https://learn.microsoft.com/en-us/azure/cognitive-services/openai/how-to/create-resource?pivots=web-portal) to do so.

### Configuring OpenID Connect in Azure

Execute `chmod` command on [aad-federated-cred.sh](../../../tools/deploy/module0/aad-federated-cred.sh) script to make it executable:

```bash
chmod +x ./tools/deploy/module0/aad-federated-cred.sh
```

* execute [aad-federated-cred.sh](../../../tools/deploy/module0/aad-federated-cred.sh), passing your github username as the argument, as shown below:

```bash
./tools/deploy/module0/aad-federated-cred.sh <your-github-username>
```

* note down the **appId** echoed for use in next step

app registration looks like:
![image](https://user-images.githubusercontent.com/48259636/236104024-a4308244-821c-4ddc-8cca-d45da0eefbf6.png)
with federated credentials:
![image](https://user-images.githubusercontent.com/48259636/236104075-5b651d08-78a0-4e1c-b78a-63bb1a0990c3.png)


### Setting Github Actions secrets

1. In your forked Github repository, click on the `Settings` tab.
2. In the left-hand menu, expand `Secrets and variables`, and click on `Actions`.
3. Click on the `New repository secret` button for each of the following secrets:
   * `AZURE_SUBSCRIPTION_ID`(run `az account show --query id -o tsv` to get the value)
   * `AZURE_TENANT_ID` (run `az account show --query tenantId --output tsv` to get the value)
   * `AZURE_CLIENT_ID` (this is the `appId` from running the previous step)
   * `AZURE_RESOURCE_GROUP` (this is the `resourceGroupName` from earlier step, which is `openai-levelup-rg`)

### Enable GitHub Actions workflow

* Enable **GitHub Actions** for your repository by clicking on the **Actions** tab, and clicking on the `I understand my workflows, go ahead and enable them` button.

### Creation of Azure Storage Account and Azure Function App

  * This is achieved by running the Github Actions workflow file [module1-infra-worflow.yaml](../../../.github/workflows/module1-infra-workflow.yaml) which executes [module2-infra.bicep](../../../tools/deploy/Module1/infra/module1-infra.bicep) Bicep template. To trigger this workflow manually:
    1. click on the `Actions` tab.
    2. Select `Deploy Module 1 Infrastructure` workflow.
    3. Click on the `Run workflow` button

### Deploying the Azure Function App code

* Deploy the Azure Function App code using Github Actions workflow file [module2-code-workflow.yaml](../../../.github/workflows/module1-code-workflow.yaml) as follows:
  1. In Azure portal, navigate to the Function App that was deployed in the last step.
  2. Click **Get publish profile** and download **.PublishSettings** file.
  3. Open the **.PublishSettings** file and copy the XML content.
  4. Paste the XML content to your GitHub Repository > Settings > Secrets > Add a new secret > **AZURE_FUNCTIONAPP_PUBLISH_PROFILE**
  5. Trigger this workflow manually:
    * click on the `Actions` tab.
    * Select `Deploy Azure Function App` workflow.
    * Click on the `Run workflow` button

* Ensure you created your OpenAI service
for instance:
![image](https://user-images.githubusercontent.com/48259636/236108851-2fbbea61-a46e-438b-8ed0-d242b8ad3f3d.png)
add text-davinci-003 in OpenAI Studio
![image](https://user-images.githubusercontent.com/48259636/236110858-a256d495-ffe9-46b7-811c-bef42ee01d3f.png)
![image](https://user-images.githubusercontent.com/48259636/236110975-7d627379-6a91-4630-a610-a491e267e32e.png)
then deploy model:
![image](https://user-images.githubusercontent.com/48259636/236111688-b408cce9-409b-4c9b-88b9-da8f8d9d6936.png)



* Configure following **Application Settings** for the Azure Function by going to your `function app > Configuration > Application Settings`:
  1. OPENAI_API_BASE - Azure OpenAI API Endpoint URL (e.g. https://openai-demo-ahmedbham.openai.azure.com/)
  2. OPENAI_API_KEY - Azure OpenAI API Key
  3. OPENAI_API_MODEL - "text-davinci-003" (set it equal to the `model name` you provided when deploying the `text-davinci-003` **model** in Azure OpenAI Studio)
**Remember to click Save after adding the above settings**

### Creating and configuring Event Grid Subscription

* Create an `Event Grid Subscription` to the Azure Function App Resource from the Azure Storage Account for "Blob Created" events in Azure portal:
  1. Navigate to your `storage account > Events > + Event Subscription`
  2. Set `Event Schema` to `Event Grid Schema``
  3. Set `System Topic Name` to `classification`
  4. Select only `Blob Created` event type
  5. Select`Function App` as the `Endpoint Type`
  6. Set `Endpoint`value by selecting the correct `Subscription`, `Resource Group`, `Function App`, `Slot`, and `Function` from the dropdowns
  7. Click `Create` to create the subscription

![Event Grid Subscription Page](../../assets/images/module1/module1-create-event-subscription.png)

## Testing Transaction Classification App

* Open the sample transaction file [25000_spend_dataset_current_25.csv](../../../tools/deploy/Module1/data/25000_spend_dataset_current_25.csv) and notice that the **classification** column is empty. This is the column that will be populated by the Azure Function by calling Azure OpenAI API.   	
* Upload this file to the **classification** blob container: `portal > storage account > containers > classification > upload`
* After few seconds, download the updated file from the **output** blob container `portal > storage account > containers > output > download`
* Open the file and notice the **classification** column is populated with the predicted category for each transaction.

## Delete Resources

* Delete all resources created in this lab by deleting the resource group that was created in the first step of this lab.

```bash
az group delete --name <resource-group-name> --yes
```
