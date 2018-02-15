#Variables for HXE AKS deployment
$resourceGroupName='aks-hxe-rg'
$aksClusterName='aks-hxe-cluster'

$inputKey=Read-Host '(1) West Europe
(2) East US
(3) Central US
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
}

#Create resource group
az group create --name $resourceGroupName --location $azureRegion --output table

#Create AKS cluster
az aks create --resource-group $resourceGroupName --name $aksClusterName --node-count 3 --node-vm-size Standard_A4m_v2 --generate-ssh-keys --output table

#Getting AKS cluster credentials
az aks get-credentials --resource-group $resourceGroupName --name $aksClusterName

#Prepare deployment files and create master password secret
$credential=Get-Credential -UserName hxeMasterPassword
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($credential.Password)
$masterPassword=[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$jsonDefinition='{'+'"'+'master_password'+'"'+' : '+'"'+$masterPassword+'"'+'}'
$jsonEncoded=Write-Output $jsonDefinition|base64

$yamlDefinition='apiVersion: v1
data:
  password.json: '+$jsonEncoded+'
kind: Secret
metadata:
  name: masterpassword
  namespace: default
type: Opaque'

Write-Output $yamlDefinition > secrets.yaml

$masterPassword=$null
$BSTR=$null
$credential=$null

kubectl create -f ./secrets.yaml


#Enter Docker account details and create docker registry secret
$credential=Get-Credential -Title 'Enter Docker account username and password'
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($credential.Password)
$dockerPassword=[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
$dockerEmail=Read-Host 'Enter e-mail address of your Docker account'
$dockerUsername=$credential.UserName

kubectl create secret docker-registry docker-secret --docker-server=https://index.docker.io/v1/ --docker-username=$dockerUsername --docker-password=$dockerPassword --docker-email=$dockerEmail

$dockerPassword=$null
$dockerUsername=$null
$dockerEmail=$null
$BSTR=$null
$credential=$null

#HANA Express Edition deployment
wget https://raw.githubusercontent.com/neumanndaniel/kubernetes/master/hxe-aks/deploy_HXE_AKS.yaml

kubectl create -f ./deploy_HXE_AKS.yaml
