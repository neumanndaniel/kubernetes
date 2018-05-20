#Variables for HXE ACI deployment
$registryLoginServer='https://registry-1.docker.io/v2/'
$gitHubAciHxeAksUri='https://raw.githubusercontent.com/neumanndaniel/kubernetes/master/hxe-aci/deploy_HXE_ACI.yaml'

#Prepare deployment files and create master password secret
$credential=Get-Credential -UserName hxeMasterPassword
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($credential.Password)
$masterPassword=[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$jsonDefinition='{'+'"'+'master_password'+'"'+' : '+'"'+$masterPassword+'"'+'}'
$jsonEncoded=Write-Output $jsonDefinition|base64

$yamlDefinition='apiVersion: v1
data:
  masterPassword.json: '+$jsonEncoded+'
kind: Secret
metadata:
  name: masterpassword
  namespace: default
type: Opaque'

Write-Output $yamlDefinition > secrets.yaml

$masterPassword=$null
$BSTR=$null
$credential=$null

kubectl apply -f ./secrets.yaml

#Enter Docker account details and create docker registry secret
$credential=Get-Credential -Title 'Enter Docker account username and password'
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($credential.Password)
$dockerPassword=[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
$dockerEmail=Read-Host 'Enter e-mail address of your Docker account'
$dockerUsername=$credential.UserName

kubectl create secret docker-registry docker-secret --docker-server=$registryLoginServer --docker-username=$dockerUsername --docker-password=$dockerPassword --docker-email=$dockerEmail

$dockerPassword=$null
$dockerUsername=$null
$dockerEmail=$null
$BSTR=$null
$credential=$null

#HANA Express Edition deployment
wget $gitHubAciHxeAksUri

kubectl apply -f ./deploy_HXE_ACI.yaml
