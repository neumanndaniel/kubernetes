#!/bin/bash

RESOURCE_GROUP=$1
NAME=$2

kubectl apply -f namespace.yaml
./create-secret.sh $RESOURCE_GROUP $NAME
kubectl apply -f config-map.yaml
kubectl apply -f network-policy.yaml
kubectl apply -f peer-authentication.yaml
kubectl apply -f deployment.yaml
kubectl apply -f envoyfilter-global.yaml
kubectl apply -f container-azm-ms-agentconfig.yaml