#!/bin/bash

set -e

kind create cluster --config=single-node.yaml

# Calico
curl https://docs.projectcalico.org/manifests/calico.yaml | kubectl apply -f -

# CoreDNS
kubectl scale deployment --replicas 1 coredns --namespace kube-system

# Metrics Server
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo update
helm upgrade metrics-server --install --set "args={--kubelet-insecure-tls, --kubelet-preferred-address-types=InternalIP}" stable/metrics-server --namespace kube-system
