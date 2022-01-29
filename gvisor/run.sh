#!/bin/sh

URL="https://raw.githubusercontent.com/neumanndaniel/kubernetes/master/gvisor/config.toml"

wget ${URL} -O /k8s-node/config.toml
cp /install-gvisor.sh /k8s-node

/usr/bin/nsenter -m/proc/1/ns/mnt -- chmod u+x /tmp/gvisor/install-gvisor.sh
/usr/bin/nsenter -m/proc/1/ns/mnt /tmp/gvisor/install-gvisor.sh
/usr/bin/nsenter -m/proc/1/ns/mnt -- cp /etc/containerd/config.toml /etc/containerd/config.toml.org
/usr/bin/nsenter -m/proc/1/ns/mnt -- cp /tmp/gvisor/config.toml /etc/containerd/config.toml
/usr/bin/nsenter -m/proc/1/ns/mnt -- systemctl restart containerd

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Successfully installed gvisor and restarted containerd on node ${NODE_NAME}."

sleep infinity