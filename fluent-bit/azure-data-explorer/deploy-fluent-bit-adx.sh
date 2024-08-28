#!/bin/bash

TENANT_ID=$1
CLIENT_ID=$2
CLIENT_SECRET=$3

kubectl apply -f namespace.yaml
kubectl apply -f service-account.yaml
kubectl apply -f cluster-role.yaml
kubectl apply -f cluster-role-binding.yaml

kubectl apply -f adx-output/config-map.yaml

kubectl create secret generic azuredataexplorer -n logging \
  --from-literal=tenant_id="${TENANT_ID}" \
  --from-literal=client_id="${CLIENT_ID}" \
  --from-literal=client_secret="${CLIENT_SECRET}" \
  || true

kubectl apply -f adx-output/daemon-set.yaml
