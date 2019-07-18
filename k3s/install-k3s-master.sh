#!/bin/bash

set -e

MASTER=$(hostname)

curl -sfL https://get.k3s.io -o install.sh
chmod +x install.sh
./install.sh server --kubelet-arg="address=0.0.0.0"
systemctl status k3s

sudo apt update
sudo apt install jq vim git -y
kubectl taint nodes $MASTER node-role.kubernetes.io/master=true:NoSchedule
kubectl label node $MASTER kubernetes.io/role=master node-role.kubernetes.io/master=
