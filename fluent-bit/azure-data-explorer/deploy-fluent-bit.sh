#!/bin/bash

RESOURCE_GROUP=$1
EVENT_HUB_NAMESPACE=$2
EVENT_HUB=$3
SHARED_ACCESS_POLICY_NAME=$4

kubectl apply -f namespace.yaml
kubectl apply -f service-account.yaml
kubectl apply -f cluster-role.yaml
kubectl apply -f cluster-role-binding.yaml

kubectl apply -f config-map.yaml

kubectl create secret generic azureeventhub -n logging \
  --from-literal=namespace="${EVENT_HUB_NAMESPACE}" \
  --from-literal=topic="${EVENT_HUB}" \
  --from-literal=connection_string="$(az eventhubs eventhub authorization-rule keys list --resource-group ${RESOURCE_GROUP} --namespace-name ${EVENT_HUB_NAMESPACE} --eventhub-name ${EVENT_HUB} --authorization-rule-name ${SHARED_ACCESS_POLICY_NAME} | jq -r .primaryConnectionString)" \
  || true

kubectl apply -f daemon-set.yaml
