#!/bin/bash
resourceGroupName='aks-demo-rg'
aksClusterName='aks-demo-cluster'
aksAciConnectorName='aciconnector'
acrRegistryName='aksdemoacr'
omsWorkspaceName='aks-demo-oms'
gitHubTemplateUri='https://raw.githubusercontent.com/neumanndaniel/armtemplates/master/operationsmanagement/aksMonitoringSolution.json'

echo '(1) West Europe
(2) East US
(3) Southeast Asia
Enter Azure region for AKS deployment:'

read inputKey

case $inputKey in
    1)
        azureRegion='westeurope'
        ;;
    2)
        azureRegion='eastus'
        ;;
    3)
        azureRegion='southeastasia'
        ;;
esac

#Create Kubernetes service principal account
echo '>>Creating Kubernetes service principal account:'
kubernetesServicePrincipal = az ad sp create-for-rbac --skip-assignment --verbose

#Create resource group
echo '>>Creating resource group:'
az group create --name $resourceGroupName --location $azureRegion --output table

#Create ACR container registry
echo '>>Creating ACR container registry:'
az acr create --resource-group $resourceGroupName --name $acrRegistryName --sku Basic --admin-enabled true --output table

#Assigning AKS Service Principal the reader role on ACR
acrId=$(az acr show --resource-group $resourceGroupName --name $acrRegistryName --query "id" --output tsv)

az role assignment create --assignee $(echo $kubernetesServicePrincipal|jq - .appId) --role Reader --scope $acrId --verbose --output table

#Create AKS cluster
echo '>>Creating AKS cluster:'
az aks create --resource-group $resourceGroupName --name $aksClusterName --node-count 1 --node-vm-size Standard_D2s_v3 --generate-ssh-keys --disable-rbac --service-principal $(echo $kubernetesServicePrincipal|jq -r .appId) --client-secret $(echo $kubernetesServicePrincipal|jq -r .password) --output table

#Getting AKS cluster credentials
echo '>>Getting AKS cluster credentials:'
az aks get-credentials --resource-group $resourceGroupName --name $aksClusterName --admin

#Deploy AKS ACI connector for Linux
echo '>>Deploying ACI connector for Linux to AKS cluster:'
helm init
echo '>>Waiting 30 seconds to spin up tiller pod:'
sleep 30
az aks install-connector --resource-group $resourceGroupName --name $aksClusterName --connector-name $aksAciConnectorName --service-principal $(echo $kubernetesServicePrincipal|jq -r .appId) --client-secret $(echo $kubernetesServicePrincipal|jq -r .password)

kubernetesServicePrincipal=$(echo $kubernetesServicePrincipal > /dev/null)

#Create Log Analytics workspace, add the container monitoring solution to the workspace and deploy Log Analytics agent on the AKS cluster
echo '>>Creating Log Analytics workspace and deploy OMS agent to AKS cluster:'
az group deployment create --resource-group $resourceGroupName --template-uri $gitHubTemplateUri --parameters workspaceName=$omsWorkspaceName --verbose > /dev/null

workspaceResourceId=$(az resource show --resource-group $resourceGroupName --name $omsWorkspaceName --resource-type 'Microsoft.OperationalInsights/workspaces' --verbose)

az aks enable-addons --addons monitoring --resource-group $resourceGroupName --name $aksClusterName --workspace-resource-id $(echo $workspaceResourceId|jq -r .id) --output table
