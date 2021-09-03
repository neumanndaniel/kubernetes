#!/bin/bash

set -e

kind create cluster --config=single-node.yaml

# Calico
kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
kubectl apply -f ./calico-config.yaml

sleep 120

# Metrics Server
kubectl config set-context --current --namespace kube-system

helm upgrade metrics-server --install \
--set apiService.create=true \
--set extraArgs.kubelet-insecure-tls=true \
--set extraArgs.kubelet-preferred-address-types=InternalIP \
bitnami/metrics-server --namespace kube-system
