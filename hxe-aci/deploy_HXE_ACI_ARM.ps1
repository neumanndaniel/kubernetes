#Variables for HXE ACI deployment
$resourceGroupName='aci-hxe-rg'
$aciInstance='aci-hxe-instance'
$fileShareName='hxe-config'
$aciHxeImage='registry-1.docker.io/store/saplabs/hanaexpress:2.00.030.00.20180403.2'
$registryLoginServer='registry-1.docker.io'
$gitHubAciHxeUri='https://raw.githubusercontent.com/neumanndaniel/kubernetes/master/hxe-aci/aciHxe.json'

$inputKey=Read-Host '(1) West Europe
(2) North Europe
(3) East US
(4) West US
Enter Azure region for AKS deployment'
switch ($inputKey.ToUpper()) {
    1 {
        $azureRegion='westeurope'
    }
    2 {
        $azureRegion='northeurope'
    }
    3 {
        $azureRegion='eastus'
    }
    4 {
        $azureRegion='westus'
    }
}

#Create resource group
az group create --name $resourceGroupName --location $azureRegion --output table

#Prepare deployment files and create master password JSON
$credential=Get-Credential -UserName hxeMasterPassword
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($credential.Password)
$masterPassword=[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$jsonDefinition='{'+'"'+'master_password'+'"'+' : '+'"'+$masterPassword+'"'+'}'

Write-Output $jsonDefinition > masterPassword.json

$jsonDefinition=$null
$BSTR=$null
$credential=$null

#Create Azure file share and upload masterPassword.json
$storageAccountName=(New-Guid).Guid
$storageAccountName=$storageAccountName -replace "-",""
$storageAccountName=$storageAccountName.Substring(0,20)

az storage account create --name $storageAccountName --resource-group $resourceGroupName --kind StorageV2 --sku Standard_LRS --https-only true --encryption-services blob file
az storage share create --name $fileShareName --account-name $storageAccountName
az storage file upload --share-name $fileShareName --account-name $storageAccountName --source ./masterPassword.json
$storageAccountKeys = az storage account keys list --account-name $storageAccountName --resource-group $resourceGroupName | ConvertFrom-Json

#Enter Docker account details and create docker registry secret
$credential=Get-Credential -Title 'Enter Docker account username and password'
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($credential.Password)
$dockerPassword=[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
$dockerUsername=$credential.UserName

#HANA Express Edition deployment on ACI
az group deployment create --resource-group $resourceGroupName --name $aciInstance `
--template-uri $gitHubAciHxeUri --parameters containerName=$aciInstance containerImage=$aciHxeImage `
imageRegistryLoginServer=$registryLoginServer imageUsername=$dockerUsername imagePassword=$dockerPassword `
osType=Linux numberCores=4 memory=14 ipType=Public fileShareStorageAccount=$storageAccountName fileShareName=$fileShareName

$dockerPassword=$null
$dockerUsername=$null
$BSTR=$null
$credential=$null
$storageAccountKeys=$null
