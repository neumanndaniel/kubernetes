#!/bin/bash

RESOURCE_GROUP=$1
NAME=$2
DATA=$(az redis show --resource-group $RESOURCE_GROUP --name $NAME)
HOST_URL="$(echo $DATA | jq -r .hostName):$(echo $DATA | jq -r .sslPort)"

PASSWORD=$(az redis list-keys --resource-group $RESOURCE_GROUP --name $NAME | jq -r .primaryKey | tr -d '\n' | base64)
URL=$(echo -n $HOST_URL | base64)

echo "apiVersion: v1
data:
  password: $PASSWORD
  url: $URL
kind: Secret
metadata:
  name: redis
  namespace: ratelimit
type: Opaque" | kubectl apply -f - || true