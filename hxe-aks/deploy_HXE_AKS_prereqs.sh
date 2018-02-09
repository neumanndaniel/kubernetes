#!/bin/bash

#Azure CLI
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" | tee /etc/apt/sources.list.d/azure-cli.list
apt-key adv --keyserver packages.microsoft.com --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893
apt-get install apt-transport-https
apt-get update && apt-get install azure-cli

#PowerShell Core
curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
if [ $(cat /etc/*_version|grep -c 'Ubuntu 16.04') -ge 1 ]
then
    curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list | tee /etc/apt/sources.list.d/microsoft.list
else
    curl https://packages.microsoft.com/config/ubuntu/17.04/prod.list | tee /etc/apt/sources.list.d/microsoft.list
fi
apt-get update
apt-get install -y powershell
