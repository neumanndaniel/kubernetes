#!/bin/bash

set -e
set -o pipefail

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Gathering information about the Kubernetes cluster and the latest base image..."
VMSS=$(kubectl get nodes|grep vmss --max-count=1|cut -d ' ' -f1|rev|cut -c 7-|rev)
RESOURCE_GROUP=$(kubectl get node $(kubectl get nodes|grep vmss --max-count=1|cut -d ' ' -f 1) -o json|jq '.metadata.labels'|grep kubernetes.azure.com/cluster|cut -d '"' -f4)

VMSS_PROPERTIES=$(az vmss show --resource-group $RESOURCE_GROUP --name $VMSS)
OFFER=$(echo $VMSS_PROPERTIES|jq '.virtualMachineProfile.storageProfile.imageReference.offer'|cut -d '"' -f 2)
PUBLISHER=$(echo $VMSS_PROPERTIES|jq '.virtualMachineProfile.storageProfile.imageReference.publisher'|cut -d '"' -f 2)
SKU_TEMP=$(echo $VMSS_PROPERTIES|jq '.virtualMachineProfile.storageProfile.imageReference.sku'|cut -d '"' -f 2|rev|cut -c 7-|rev)
SKU=$SKU_TEMP$(date +"%Y%m")

BASE_IMAGES=$(az vm image list --offer $OFFER --publisher $PUBLISHER --sku $SKU --all)
if [[ $(echo $BASE_IMAGES|jq length) -eq 0 ]]; then
    SKU=$SKU_TEMP$(date +"%Y%m" --date="last month")
    BASE_IMAGES=$(az vm image list --offer $OFFER --publisher $PUBLISHER --sku $SKU --all)
fi
BASE_IMAGE_COUNT=$(echo $BASE_IMAGES|jq length)
LATEST_BASE_IMAGE=$(echo $BASE_IMAGES|jq ".[$BASE_IMAGE_COUNT-1]")

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Updating base image..."
az vmss update --resource-group $RESOURCE_GROUP --name $VMSS \
    --set virtualMachineProfile.storageProfile.imageReference.sku=$(echo $LATEST_BASE_IMAGE|jq '.sku'|cut -d '"' -f 2) \
        virtualMachineProfile.storageProfile.imageReference.version=$(echo $LATEST_BASE_IMAGE|jq '.version'|cut -d '"' -f 2)|jq '.virtualMachineProfile.storageProfile.imageReference'

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Updating VMSS instances..."
VMSS_INSTANCES=$(kubectl get nodes|grep vmss|cut -d ' ' -f1)

for ITEM in $VMSS_INSTANCES; do
    TEMP_INSTANCE_ID=$(kubectl get nodes $ITEM -o yaml|grep providerID)
    INSTANCE_ID=$(echo $TEMP_INSTANCE_ID|cut -d '/' -f13)
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Draining node $ITEM..."
    kubectl drain $ITEM --ignore-daemonsets --delete-local-data --force
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Updating VMSS instance $ITEM..."
    az vmss update-instances --instance-ids $INSTANCE_ID --name $VMSS --resource-group $RESOURCE_GROUP
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Uncordon node $ITEM..."
    kubectl uncordon $ITEM
done

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Base image update finished..."