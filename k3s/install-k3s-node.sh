#!/bin/bash
K3SMASTER=$1
K3SMASTERIPADDRESS=$2
NODE_TOKEN=$3
NODE=$(hostname)

echo "$K3SMASTERIPADDRESS       $K3SMASTER" | sudo tee -a /etc/hosts
curl -sfL https://get.k3s.io -o install.sh
chmod +x install.sh
./install.sh agent --server https://$K3SMASTER:6443 --kubelet-arg="address=0.0.0.0" --token $NODE_TOKEN
systemctl status k3s-agent

sudo apt update
sudo apt install jq vim -y

kubectl label node $NODE kubernetes.io/role=agent node-role.kubernetes.io/agent=
