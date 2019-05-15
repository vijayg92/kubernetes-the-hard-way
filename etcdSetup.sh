#!/bin/bash

ETCD_VERSION=$1
ETCD_CLUSTER_DETAILS=$2
ETCD_NAME=$(hostame -s)
INTERNAL_IP=$(hostname -i)  

if [ $# -eq 0 ]; then
    echo "Please provide valid arguments!!"
    echo "Usage: etcdSetup.sh ETCD_VERSION ETCD_CLUSTER_DETAILS"
    exit -1
fi

if [ ! -f /tmp/etcd-v${1}-linux-amd64.tar.gz ]; then
  wget -P /tmp --timestamping https://github.com/coreos/etcd/releases/download/v${1}/etcd-v${1}-linux-amd64.tar.gz
  tar -xvzf /tmp/etcd-v${1}-linux-amd64.tar.gz
  mv /tmp/etcd-v${1}-linux-amd64/etcd* /usr/local/bin/
fi

mkdir -p /etc/etcd /var/lib/etcd
cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/

cat <<EOF | tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster ${ETCD_CLUSTER_DETAILS} \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable etcd
systemctl start etcd

ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem

