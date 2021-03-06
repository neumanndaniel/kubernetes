#!/bin/bash

set -e
set -o pipefail

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Gathering information about the Azure Kubernetes Service cluster and the latest base image..."
RESOURCE_GROUP=$(kubectl get node $(kubectl get nodes|grep vmss --max-count=1|cut -d ' ' -f 1) -o json|jq '.metadata.labels'|grep kubernetes.azure.com/cluster|cut -d '"' -f4)
VM_SCALE_SETS=$(az vmss list --resource-group $RESOURCE_GROUP| jq -r '.[].name')

for VMSS in $VM_SCALE_SETS; do
    VMSS_PROPERTIES=$(az vmss show --resource-group $RESOURCE_GROUP --name $VMSS)

    if [[ $(echo $VMSS_PROPERTIES|jq -r '.virtualMachineProfile.storageProfile.imageReference.offer') == "WindowsServer" ]]; then
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] Skipping Windows VMSS $VMSS..."
        continue
    fi

    OFFER=$(echo $VMSS_PROPERTIES|jq -r '.virtualMachineProfile.storageProfile.imageReference.offer')
    PUBLISHER=$(echo $VMSS_PROPERTIES|jq -r '.virtualMachineProfile.storageProfile.imageReference.publisher')
    SKU_TEMP=$(echo $VMSS_PROPERTIES|jq -r '.virtualMachineProfile.storageProfile.imageReference.sku'|rev|cut -c 7-|rev)
    SKU=$SKU_TEMP$(date +"%Y%m")

    BASE_IMAGES=$(az vm image list --offer $OFFER --publisher $PUBLISHER --sku $SKU --all)
    if [[ $(echo $BASE_IMAGES|jq length) -eq 0 ]]; then
        SKU=$SKU_TEMP$(date +"%Y%m" --date="last month")
        BASE_IMAGES=$(az vm image list --offer $OFFER --publisher $PUBLISHER --sku $SKU --all)
    fi
    BASE_IMAGE_COUNT=$(echo $BASE_IMAGES|jq length)
    LATEST_BASE_IMAGE=$(echo $BASE_IMAGES|jq ".[$BASE_IMAGE_COUNT-1]")

    if [[ $(echo $LATEST_BASE_IMAGE|jq -r '.version') == $(echo $VMSS_PROPERTIES|jq -r '.virtualMachineProfile.storageProfile.imageReference.version') ]]; then
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] Skipping VMSS $VMSS. No newer base image version available..."
        continue
    fi

    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Updating base image for VMSS $VMSS..."
    az vmss update --resource-group $RESOURCE_GROUP --name $VMSS \
        --set virtualMachineProfile.storageProfile.imageReference.sku=$(echo $LATEST_BASE_IMAGE|jq -r '.sku') \
            virtualMachineProfile.storageProfile.imageReference.version=$(echo $LATEST_BASE_IMAGE|jq -r '.version')|jq '.virtualMachineProfile.storageProfile.imageReference'
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Updating VMSS instances..."
    VMSS_INSTANCES=$(kubectl get nodes|grep $VMSS|cut -d ' ' -f1)
    for INSTANCE in $VMSS_INSTANCES; do
        TEMP_INSTANCE_ID=$(kubectl get nodes $INSTANCE -o yaml|grep providerID)
        INSTANCE_ID=$(echo $TEMP_INSTANCE_ID|cut -d '/' -f13)
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] Draining node $INSTANCE..."
        kubectl drain $INSTANCE --ignore-daemonsets --delete-local-data --force
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] Updating VMSS instance $INSTANCE..."
        az vmss update-instances --instance-ids $INSTANCE_ID --name $VMSS --resource-group $RESOURCE_GROUP
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] Uncordon node $INSTANCE..."
        kubectl uncordon $INSTANCE
    done
done

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Base image update finished..."
