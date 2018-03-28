#!/bin/bash
omsWorkspaceName=$1
gitHubTemplateUri='https://raw.githubusercontent.com/neumanndaniel/armtemplates/master/output/logAnalyticsWorkspace.json'
gitHubLogAnalyticsAgentUri='https://raw.githubusercontent.com/Microsoft/OMS-docker/master/Kubernetes/omsagent-ds-secrets.yaml'

#Get Log Analytics workspaceId and primary key, and deploy Log Analytics agent on the AKS cluster
output=$(az group deployment create --resource-group operations-management --template-uri $gitHubTemplateUri --parameters workspaceName=$omsWorkspaceName --verbose)

workspaceId=$(echo $output|jq -r .properties.outputs.workspaceId.value)
primaryKey=$(echo $output|jq -r .properties.outputs.primaryKey.value)

echo $workspaceId
echo $primaryKey

workspaceIdEncoded=$(echo $workspaceId|base64 --wrap=0)
primaryKeyEncoded=$(echo $primaryKey|base64 --wrap=0)

echo "apiVersion: v1
data:
  KEY: $primaryKeyEncoded
  WSID: $workspaceIdEncoded
kind: Secret
metadata:
  name: omsagent-secret
  namespace: default
type: Opaque" > omsagent-secret.yaml

kubectl apply -f ./omsagent-secret.yaml

wget $gitHubLogAnalyticsAgentUri --output-document=oms-daemonset.yaml

kubectl apply -f ./oms-daemonset.yaml
