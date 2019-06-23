#!/bin/bash

set -e

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Starting Release pre-steps..."

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Downloading latest kubectl version for linux-arm platform..."
curl -sfLO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/arm/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin/

VERSION=$(cat HELMVERSION)

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Downloading helm version $VERSION for linux-arm platform..."
curl -sfL https://get.helm.sh/helm-$VERSION-linux-arm.tar.gz -o helm.tar.gz

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Extracting tiller and helm executables..."
tar -xf helm.tar.gz
mv linux-arm/helm /usr/local/bin/

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Deleting linux-arm folder..."
rm -rf linux-arm

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Finished Release pre-steps..."