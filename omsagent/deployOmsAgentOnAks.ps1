#Parameters for AKS OMS deployment
Param(
  [Parameter(Mandatory=$true,Position=1)]
  [string]$omsWorkspaceName
)

#Variables for AKS OMS deployment
$gitHubTemplateUri='https://raw.githubusercontent.com/neumanndaniel/armtemplates/master/output/logAnalyticsWorkspace.json'
$gitHubLogAnalyticsAgentUri='https://raw.githubusercontent.com/Microsoft/OMS-docker/master/Kubernetes/omsagent-ds-secrets.yaml'

#Get Log Analytics workspaceId and primary key, and deploy Log Analytics agent on the AKS cluster
$output=az group deployment create --resource-group operations-management --template-uri $gitHubTemplateUri --parameters workspaceName=$omsWorkspaceName --verbose|ConvertFrom-Json

$workspaceId=$output.properties.outputs.workspaceId.value
$primaryKey=$output.properties.outputs.primaryKey.value

$workspaceId
$primayKey
