#!/bin/bash

RESOURCE_GROUP=$1
LOG_ANALYTICS_WORKSPACE=$2

kubectl apply -f namespace.yaml
kubectl apply -f service-account.yaml
kubectl apply -f cluster-role.yaml
kubectl apply -f cluster-role-binding.yaml

kubectl apply -f config-map.yaml

kubectl create secret generic loganalytics -n logging \
  --from-literal=workspaceid="$(az monitor log-analytics workspace show -g ${RESOURCE_GROUP} -n ${LOG_ANALYTICS_WORKSPACE} | jq -r .customerId)" \
  --from-literal=workspacekey="$(az monitor log-analytics workspace get-shared-keys -g ${RESOURCE_GROUP} -n ${LOG_ANALYTICS_WORKSPACE} | jq -r .primarySharedKey)" \
  || true

kubectl apply -f daemon-set.yaml
