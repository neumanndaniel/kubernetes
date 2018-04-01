#Parameters for AKS OMS deployment
Param(
  [Parameter(Mandatory=$true,Position=1)]
  [string]$omsWorkspaceName,
  [Parameter(Mandatory=$true,Position=2)]
  [string]$resourceGroupName
)

#Variables for AKS OMS deployment
$gitHubTemplateUri='https://raw.githubusercontent.com/neumanndaniel/armtemplates/master/output/logAnalyticsWorkspace.json'
$gitHubLogAnalyticsAgentUri='https://raw.githubusercontent.com/Microsoft/OMS-docker/master/Kubernetes/omsagent-ds-secrets.yaml'

#Get Log Analytics workspaceId and primary key, and deploy Log Analytics agent on the AKS cluster
$output=az group deployment create --resource-group $resourceGroupName --template-uri $gitHubTemplateUri --parameters workspaceName=$omsWorkspaceName --verbose|ConvertFrom-Json

$workspaceId=$output.properties.outputs.workspaceId.value
$primaryKey=$output.properties.outputs.primaryKey.value

$workspaceIdEncoded=[Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($workspaceId))
$primaryKeyEncoded=[Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($primaryKey))

$yamlDefinition='apiVersion: v1
data:
  KEY: '+$primaryKeyEncoded+'
  WSID: '+$workspaceIdEncoded+'
kind: Secret
metadata:
  name: omsagent-secret
  namespace: default
type: Opaque'

Write-Output $yamlDefinition > omsagent-secret.yaml

kubectl apply -f ./omsagent-secret.yaml

Invoke-WebRequest $gitHubLogAnalyticsAgentUri -OutFile ./oms-daemonset.yaml

kubectl apply -f ./oms-daemonset.yaml
