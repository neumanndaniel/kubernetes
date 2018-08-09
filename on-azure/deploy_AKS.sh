#!/bin/bash
resourceGroupName='aks-demo-rg'
aksClusterName='aks-demo-cluster'
aksAciConnectorName='aciconnector'
acrRegistryName='aksdemoacr'
omsWorkspaceName='aks-demo-oms'
gitHubTemplateUri='https://raw.githubusercontent.com/neumanndaniel/armtemplates/master/operationsmanagement/aksMonitoringSolution.json'
gitHubLogAnalyticsAgentUri='https://raw.githubusercontent.com/neumanndaniel/kubernetes/master/omsagent/oms-daemonset.yaml'
dockerEmail='AKS@AzureRM'

echo '(1) West Europe
(2) East US
(3) Central US
(4) Canada Central
(5) Canada East
(6) Australia East
(7) East US2
(8) Japan East
(9) North Europe
(10) Southeast Asia
(11) UK South
(12) West US
(13) West US2
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
        azureRegion='centralus'
        ;;
    4)
        azureRegion='canadacentral'
        ;;
    5)
        azureRegion='canadaeast'
        ;;
    6)
        azureRegion='australiaeast'
        ;;
    7)
        azureRegion='eastus2'
        ;;
    8)
        azureRegion='japaneast'
        ;;
    9)
        azureRegion='northeurope'
        ;;
    10)
        azureRegion='southeastasia'
        ;;
    11)
        azureRegion='uksouth'
        ;;
    12)
        azureRegion='westus'
        ;;
    13)
        azureRegion='westus2'
        ;;
esac

#Create resource group
echo '>>Creating resource group:'
az group create --name $resourceGroupName --location $azureRegion --output table

#Create ACR container registry
echo '>>Creating ACR container registry:'
az acr create --resource-group $resourceGroupName --name $acrRegistryName --sku Basic --admin-enabled true --output table

#Create AKS cluster
echo '>>Creating AKS cluster:'
az aks create --resource-group $resourceGroupName --name $aksClusterName --node-count 1 --node-vm-size Standard_A2_v2 --generate-ssh-keys --output table

#Getting AKS cluster credentials
echo '>>Getting AKS cluster credentials:'
az aks get-credentials --resource-group $resourceGroupName --name $aksClusterName

#Deploy AKS ACI connector for Linux
echo '>>Deploying ACI connector for Linux to AKS cluster:'
helm init
echo '>>Waiting 30 seconds to spin up tiller pod:'
sleep 30
az aks install-connector --resource-group $resourceGroupName --name $aksClusterName --connector-name $aksAciConnectorName

#Getting ACR container registry credentials and login
#echo '>>Getting ACR container registry credentials and create Kubernetes secret for ACR:'
#acrCredentials=$(az acr credential show --resource-group $resourceGroupName --name $acrRegistryName)

#acrUri=$(echo $acrRegistryName.azurecr.io)
#dockerUsername=$(echo $acrCredentials|jq -r .username)
#dockerPassword=$(echo $acrCredentials|jq -r .passwords[0].value)

#kubectl create secret docker-registry $acrRegistryName --docker-server=$acrUri --docker-email=$dockerEmail --docker-username=$dockerUsername --docker-password=$dockerPassword

#Assigning Microsoft default AKS Service Principal (AzureContainerService) the reader role on ACR
clientId='7319c514-987d-4e9b-ac3d-d38c4f427f4c'
acrId=$(az acr show --resource-group $resourceGroupName --name $acrRegistryName --query "id" --output tsv)

az role assignment create --assignee $clientId --role Reader --scope $acrId --verbose --output table

#Create Log Analytics workspace, add the container monitoring solution to the workspace and deploy Log Analytics agent on the AKS cluster
echo '>>Creating Log Analytics workspace and deploy OMS agent to AKS cluster:'
output=$(az group deployment create --resource-group $resourceGroupName --template-uri $gitHubTemplateUri --parameters workspaceName=$omsWorkspaceName --verbose)

workspaceId=$(echo $output|jq -r .properties.outputs.workspaceId.value)
primaryKey=$(echo $output|jq -r .properties.outputs.primaryKey.value)

kubectl create secret generic omsagent-secret --from-literal=WSID=$workspaceId --from-literal=KEY=$primaryKey --namespace kube-system

wget $gitHubLogAnalyticsAgentUri --output-document=oms-daemonset.yaml

kubectl apply -f ./oms-daemonset.yaml