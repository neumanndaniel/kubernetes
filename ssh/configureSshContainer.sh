#!/bin/bash

set -e

kubectl exec aks-ssh -c aks-ssh -- apk update
kubectl exec aks-ssh -c aks-ssh -- apk add openssh-client bash
kubectl cp ~/.ssh/id_rsa aks-ssh:/id_rsa
kubectl exec aks-ssh -c aks-ssh chmod 0600 id_rsa
