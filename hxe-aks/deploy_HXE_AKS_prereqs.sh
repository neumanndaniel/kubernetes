#!/bin/bash

masterPassword=$1

mkdir -p /data/hxe_pv
chown 12000:79 /data/hxe_pv

echo {'"'master_password'"' : '"'$masterPassword'"'} > /data/hxe_pv/password.json

chmod 600 /data/hxe_pv/password.json
chown 12000:79 /data/hxe_pv/password.json
