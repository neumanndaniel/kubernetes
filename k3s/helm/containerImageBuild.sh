#!/bin/bash

set -e

BUILDNUMBER=$1

VERSION=$(cat HELMVERSION)

az acr build --registry acr --image "tiller:$VERSION" --image "tiller:$BUILDNUMBER" .
