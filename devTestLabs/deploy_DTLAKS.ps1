#Variables for DevTest Lab deployment
$region = 'northeurope'
$azureAutomationregion = 'northeurope'
$resourceGroupName = 'dtlSession'
$name = 'dtlSession'
$customRbacRoleName="dtlAksCredentials"
$customRbacRoleId='{USE THE CUSTOMROLEDEPLOYMENT.PS1 SCRIPT TO GET THE ROLE ID}'
$connectionName = 'AzureRunAsConnection'
$aadServicePrincipalIdName = 'kubernetesId'
$aadServicePrincipalSecretName = 'kubernetesSecret'
$gitHubTemplateUri = 'https://raw.githubusercontent.com/neumanndaniel/armtemplates/master/development/devTestLabs.json'
$gitHubLogicAppWorkflowUri = 'https://raw.githubusercontent.com/neumanndaniel/kubernetes/master/devTestLabs/logicApp.json'
$gitHubSecretProvisoningRunbookUri = 'https://raw.githubusercontent.com/neumanndaniel/kubernetes/master/devTestLabs/secretProvisioning.ps1'

#Create DevTest Lab resource group
Write-Output '>>Creating resource group:'
az group create --name $resourceGroupName --location $region --verbose --output table

#Create Azure Automation account
Write-Output '>>Creating Azure Automation account:'
New-AzureRmAutomationAccount -ResourceGroupName $resourceGroupName -Name $name -Location $azureAutomationregion -Verbose

#Create Azure Automation run as accounts
Write-Output ">>Open the Azure portal https://portal.azure.com and generate the run as accounts for the created Azure Automation account $name."

Do {
    Write-Output '>>Sleeping 30 seconds...'
    Start-Sleep 30
    Write-Output '>>Checking if Automation run as account has been created...'
    $automationAccount = Get-AzureRmAutomationConnection -Name $connectionName -ResourceGroupName $resourceGroupName -AutomationAccountName $name -ErrorAction SilentlyContinue
}While ($automationAccount -eq $null)

Write-Output '>>Automation run as account has been successfully created!'

#Import necessary Azure PowerShell module AzureRm.profile
Write-Output '>>Importing the Azure PowerShell module AzureRm.profile'
New-AzureRmAutomationModule -ResourceGroupName $resourceGroupName -AutomationAccountName $name -Name 'AzureRm.profile' -ContentLink 'https://www.powershellgallery.com/api/v2/package/AzureRm.profile/5.0.1'
Write-Output '>>AzureRm.profile module has been successfully imported!'

#Import secretProvisioning.ps1
Write-Output '>>Import secretProvisioning.ps1 runbook...'
Invoke-WebRequest $gitHubSecretProvisoningRunbookUri -OutFile ./secretProvisioning.ps1
Import-AzureRmAutomationRunbook -Path ./secretProvisioning.ps1 -ResourceGroupName $resourceGroupName -AutomationAccountName $name -Type PowerShell -Published -Force -Verbose

#Create Azure DevTest Lab
Write-Output '>>Creating Azure DevTest Lab:'
az group deployment create --resource-group $resourceGroupName --template-uri $gitHubTemplateUri --parameters labName=$name --verbose

#Set access on default DevTest Lab Key Vault for the Azure Automation run as account and current user context
Write-Output '>>Setting ACL on DTL Key Vault for Azure Automation run as account:'
$defaultVaultName = (az keyvault list --resource-group $resourceGroupName | ConvertFrom-Json).name
$secretPermissions = 'backup', 'delete', 'get', 'list', 'recover', 'restore', 'set'
az keyvault set-policy --name $defaultVaultName --spn $automationAccount.FieldDefinitionValues.ApplicationId --secret-permissions $secretPermissions --verbose --output table

Write-Output '>>Setting ACL on DTL Key Vault for current user:'
$currentUserContext = az account show
$currentUser = ((az ad user show --upn-or-object-id ($currentUserContext|ConvertFrom-Json).user.name)|ConvertFrom-Json).userPrincipalName
az keyvault set-policy --name $defaultVaultName --upn $currentUser --secret-permissions $secretPermissions --verbose --output table

#Create Kubernetes service principal account
Write-Output '>>Creating Kubernetes service principal account:'
$kubernetesServicePrincipal = az ad sp create-for-rbac --skip-assignment --verbose

#Save Kubernetes service principal id, secret and custom RBAC role id to default DevTest Lab Key Vault
Write-Output '>>Saving Kubernetes service principal id and secret in DTL Key Vault:'
$null = az keyvault secret set --vault-name $defaultVaultName --name $aadServicePrincipalSecretName --value ($kubernetesServicePrincipal|ConvertFrom-Json).password --verbose
$null = az keyvault secret set --vault-name $defaultVaultName --name $aadServicePrincipalIdName --value ($kubernetesServicePrincipal|ConvertFrom-Json).appId --verbose
$null = az keyvault secret set --vault-name $defaultVaultName --name $customRbacRoleName --value $customRbacRoleId --verbose
$kubernetesServicePrincipal = $null

#Depoy Logic App workflow
Write-Output '>>Creating Logic App workflow:'
az group deployment create --resource-group $resourceGroupName --template-uri $gitHubLogicAppWorkflowUri --parameters resourceGroupName=$resourceGroupName automationAccountName=$name --verbose

#Import necessary Azure PowerShell module AzureRm.keyvault
Write-Output '>>Importing the Azure PowerShell module AzureRm.keyvault'
New-AzureRmAutomationModule -ResourceGroupName $resourceGroupName -AutomationAccountName $name -Name 'AzureRm.keyvault' -ContentLink 'https://www.powershellgallery.com/api/v2/package/AzureRm.keyvault/5.0.0'
Write-Output '>>AzureRm.keyvault module has been successfully imported!'
