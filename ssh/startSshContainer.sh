#!/bin/bash

set -e

kubectl run -it --rm --generator=run-pod/v1 aks-ssh --image=alpine --labels=app=aksssh
