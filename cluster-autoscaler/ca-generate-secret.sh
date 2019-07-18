#!/bin/bash

set -e
set -o pipefail

ID=$(az account show --query id)
SUBSCRIPTION_ID=$(echo -n $ID | tr -d '"')

TENANT=$(az account show --query tenantId)
TENANT_ID=$(echo -n $TENANT | tr -d '"' | base64 --wrap=0)

read -p "What is your AKS cluster name? " AKS_CLUSTER_NAME
read -p "What is the AKS cluster resource group name? " AKS_RESOURCE_GROUP

CLUSTER_NAME=$(echo -n $AKS_CLUSTER_NAME | base64 --wrap=0)
RESOURCE_GROUP=$(echo -n $AKS_RESOURCE_GROUP | base64 --wrap=0)

PERMISSIONS=$(az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/$SUBSCRIPTION_ID")
CLIENT_ID=$(echo $PERMISSIONS | jq .appId | tr -d '"','\n' | base64 --wrap=0)
CLIENT_SECRET=$(echo $PERMISSIONS | jq .password | tr -d '"','\n' | base64 --wrap=0)

SUBSCRIPTION_ID=$(echo -n $ID | tr -d '"' | base64 --wrap=0)

NODE_RESOURCE_GROUP=$(az aks show --name $AKS_CLUSTER_NAME  --resource-group $AKS_RESOURCE_GROUP -o tsv --query 'nodeResourceGroup' | tr -d '\n'  | base64 --wrap=0)

echo "---
apiVersion: v1
kind: Secret
metadata:
    name: cluster-autoscaler-azure
    namespace: kube-system
data:
    ClientID: $CLIENT_ID
    ClientSecret: $CLIENT_SECRET
    ResourceGroup: $RESOURCE_GROUP
    SubscriptionID: $SUBSCRIPTION_ID
    TenantID: $TENANT_ID
    VMType: YWtz
    ClusterName: $CLUSTER_NAME
    NodeResourceGroup: $NODE_RESOURCE_GROUP
---"
