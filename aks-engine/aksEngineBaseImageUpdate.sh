#!/bin/bash

set -e
set -o pipefail

MSIENABLED=$(sudo cat /etc/kubernetes/azure.json | grep aadClientId | cut -d '"' -f4)
if [ "$MSIENABLED" = "msi" ]; then
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] AKS Engine cluster uses MSI and is therefore supported by the script. Script continues..."
else
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] AKS Engine cluster does not use MSI and is not supported by the script. Exiting the script..."
    exit
fi

AZCLI=$(which az)
if [ -z "$AZCLI" ]; then
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] No Azure CLI installed. Installing Azure CLI..."
    sudo apt-get install apt-transport-https lsb-release software-properties-common dirmngr -y
    AZ_REPO=$(lsb_release -cs)
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
        sudo tee /etc/apt/sources.list.d/azure-cli.list
    sudo apt-key --keyring /etc/apt/trusted.gpg.d/Microsoft.gpg adv \
        --keyserver packages.microsoft.com \
        --recv-keys BC528686B50D79E339D3721CEB3E94ADBE1229CF
    sudo apt-get update
    sudo apt-get install azure-cli
else
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Azure CLI installed. Script continues with updating the base image..."
fi

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Logging in to Azure via Managed Service Identity..."
NULL=$(az login --identity)

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Gathering information about the Kubernetes cluster and the latest base image..."
VMSS=$(kubectl get nodes|grep vmss --max-count=1|cut -d ' ' -f1|rev|cut -c 7-|rev)
RESOURCEGROUP=$(kubectl get node $(kubectl get nodes|grep vmss --max-count=1| cut -d ' ' -f 1) -o json | jq .metadata.labels|grep kubernetes.azure.com/cluster|cut -d '"' -f4)

VMSSPROPERTIES=$(az vmss show --resource-group $RESOURCEGROUP --name $VMSS)
OFFER=$(echo $VMSSPROPERTIES| jq .virtualMachineProfile.storageProfile.imageReference.offer|cut -d '"' -f 2)
PUBLISHER=$(echo $VMSSPROPERTIES| jq .virtualMachineProfile.storageProfile.imageReference.publisher|cut -d '"' -f 2)
SKUTEMP=$(echo $VMSSPROPERTIES| jq .virtualMachineProfile.storageProfile.imageReference.sku|cut -d '"' -f 2|rev|cut -c 7-|rev)
SKU=$SKUTEMP$(date +"%Y%m")

BASEIMAGES=$(az vm image list --offer $OFFER --publisher $PUBLISHER --sku $SKU --all)
if [ $(echo $BASEIMAGES | jq length) -eq 0 ]; then
    SKU=$SKUTEMP$(date +"%Y%m" --date="last month")
    BASEIMAGES=$(az vm image list --offer $OFFER --publisher $PUBLISHER --sku $SKU --all)
fi
BASEIMAGESCOUNT=$(echo $BASEIMAGES|jq length)
LATESTBASEIMAGE=$(echo $BASEIMAGES| jq .[$BASEIMAGECOUNT-1])

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Updating base image..."
az vmss update --resource-group $RESOURCEGROUP --name $VMSS \
    --set virtualMachineProfile.storageProfile.imageReference.sku=$(echo $LATESTBASEIMAGE|jq .sku|cut -d '"' -f 2) \
    virtualMachineProfile.storageProfile.imageReference.version=$(echo $LATESTBASEIMAGE|jq .version|cut -d '"' -f 2)| jq .virtualMachineProfile.storageProfile.imageReference

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Updating VMSS instances..."
VMSSINSTANCES=$(kubectl get nodes|grep vmss |cut -d ' ' -f1)

for ITEM in $VMSSINSTANCES; do
    TEMPINSTANCEID=$(kubectl get nodes $ITEM -o yaml|grep providerID)
    INSTANCEID=$(echo $TEMPINSTANCEID|cut -d '/' -f13)
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Draining node $ITEM..."
    kubectl drain $ITEM --ignore-daemonsets --delete-local-data --force
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Updating VMSS instance $ITEM..."
    az vmss update-instances --instance-ids $INSTANCEID --name $VMSS --resource-group $RESOURCEGROUP
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Uncordon node $ITEM..."
    kubectl uncordon $ITEM
done

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Base image update finished..."
