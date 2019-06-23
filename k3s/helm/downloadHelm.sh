#!/bin/bash

set -e

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Starting Docker image build pre-steps..."
VERSION=$(cat HELMVERSION)

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Downloading helm version $VERSION for linux-arm platform..."
curl -sfL https://get.helm.sh/helm-$VERSION-linux-arm.tar.gz -o helm.tar.gz

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Extracting tiller and helm executables..."
tar -xf helm.tar.gz
mv linux-arm/tiller tiller
mv linux-arm/helm helm

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Deleting linux-arm folder..."
rm -rf linux-arm

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Finished Docker image build pre-steps..."