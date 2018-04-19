#Variables for AKS deployment
$resourceGroupName='aks-demo-rg'
$aksClusterName='aks-demo-cluster'
$aksAciConnectorName='aciconnector'
$acrRegistryName='aksdemoacr'
$omsWorkspaceName='aks-demo-oms'
$gitHubTemplateUri='https://raw.githubusercontent.com/neumanndaniel/armtemplates/master/operationsmanagement/containerMonitoringSolution.json'
$gitHubLogAnalyticsAgentUri='https://raw.githubusercontent.com/Microsoft/OMS-docker/master/Kubernetes/omsagent-ds-secrets.yaml'
$dockerEmail='AKS@AzureRM'

$inputKey=Read-Host '(1) West Europe
(2) East US
(3) Central US
(4) Canada Central
(5) Canada East
Enter Azure region for AKS deployment'

switch ($inputKey.ToUpper()) {
    1 {
        $azureRegion='westeurope'
    }
    2 {
        $azureRegion='eastus'
    }
    3 {
        $azureRegion='centralus'
    }
    4 {
        $azureRegion='canadacentral'
    }
    5 {
        $azureRegion='canadaeast'
    }
}

#Create resource group
Write-Output '>>Creating resource group:'
az group create --name $resourceGroupName --location $azureRegion --output table

#Create ACR container registry
Write-Output '>>Creating ACR container registry:'
az acr create --resource-group $resourceGroupName --name $acrRegistryName --sku Basic --admin-enabled true --output table

#Create AKS cluster
Write-Output '>>Creating AKS cluster:'
az aks create --resource-group $resourceGroupName --name $aksClusterName --node-count 1 --node-vm-size Standard_A2_v2 --generate-ssh-keys --output table

#Getting AKS cluster credentials
Write-Output '>>Getting AKS cluster credentials:'
az aks get-credentials --resource-group $resourceGroupName --name $aksClusterName

#Deploy AKS ACI connector for Linux
Write-Output '>>Deploying ACI connector for Linux to AKS cluster:'
helm init
Write-Output '>>Waiting 30 seconds to spin up tiller pod:'
Start-Sleep -Seconds 30
az aks install-connector --resource-group $resourceGroupName --name $aksClusterName --connector-name $aksAciConnectorName

#Getting ACR container registry credentials and login
Write-Output '>>Getting ACR container registry credentials and create Kubernetes secret for ACR:'
$acrCredentials=az acr credential show --resource-group $resourceGroupName --name $acrRegistryName|ConvertFrom-Json

$acrUri=$acrRegistryName+'azurecr.io'
$dockerUsername=$acrCredentials.username
$dockerPassword=$acrCredentials.passwords[0].value

kubectl apply secret docker-registry $acrRegistryName --docker-server=$acrUri --docker-email=$dockerEmail --docker-username=$dockerUsername --docker-password=$dockerPassword

#Create Log Analytics workspace, add the container monitoring solution to the workspace and deploy Log Analytics agent on the AKS cluster
Write-Output '>>Creating Log Analytics workspace and deploy OMS agent to AKS cluster:'
$output=az group deployment create --resource-group $resourceGroupName --template-uri $gitHubTemplateUri --parameters workspaceName=$omsWorkspaceName --verbose|ConvertFrom-Json

$workspaceId=$output.properties.outputs.workspaceId.value
$primaryKey=$output.properties.outputs.primaryKey.value

kubectl apply secret generic omsagent-secret --from-literal=WSID=$workspaceId --from-literal=KEY=$primaryKey

Invoke-WebRequest $gitHubLogAnalyticsAgentUri -OutFile ./oms-daemonset.yaml

kubectl apply -f ./oms-daemonset.yaml
