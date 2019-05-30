#!/bin/bash
set -e

ETCD_VERSION="v3.3.9"
ETCD_NODE_NAME=$(hostname -f)
ETCD_NODE_IP=$(hostname -I | awk '{print $1}')
ETCD_CLUSTER_ENDPOINTS=$(grep -i ETCD_CLUSTER_CONFIGS ./clusterConfigs.txt | awk -F 'ETCD_CLUSTER_CONFIGS=' '{print $2}')

function __bootstrapETCDcluster() {

  echo ""
    rpm --query wget || yum install -y wget
    rpm --query tar || yum install -y tar
  echo ""

  if [ ! -f /usr/local/bin/etcdctl ]; then
    wget -P /tmp --timestamping https://storage.googleapis.com/etcd/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz
    tar -xvzf /tmp/etcd-${ETCD_VERSION}-linux-amd64.tar.gz
    mv etcd-${ETCD_VERSION}-linux-amd64/etcd* /usr/local/bin/
  fi
  echo ""
  echo "Creating required files & directories for ETCD"
  echo ""
  mkdir -p /etc/etcd /var/lib/etcd
  cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/
  echo ""

  echo "Creating etcd.service unit"
  echo ""
  if [ ! -f /etc/systemd/system/etcd.service ]; then
cat <<-EOF | tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NODE_NAME} \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${ETCD_NODE_IP}:2380 \\
  --listen-peer-urls https://${ETCD_NODE_IP}:2380 \\
  --listen-client-urls https://${ETCD_NODE_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${ETCD_NODE_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster ${ETCD_CLUSTER_ENDPOINTS} \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
fi

  echo ""
  echo "Starting ETCD Services"
  systemctl daemon-reload
  systemctl enable etcd
  systemctl start etcd
  echo ""
}

function __validateCluster() {
  echo ""
  echo "Validating Cluster"
  ETCDCTL_API=3 /usr/local/bin/etcdctl member list \
    --endpoints=https://127.0.0.1:2379 \
    --cacert=/etc/etcd/ca.pem \
    --cert=/etc/etcd/kubernetes.pem \
    --key=/etc/etcd/kubernetes-key.pem
  echo ""
}

## Main Function ##
echo ""
if [ ! -f "./clusterConfigs.txt" ]; then
    echo ""
    echo "Error : Unable to get clusterConfigs.txt"
    exit 1
fi
__bootstrapETCDcluster
__validateCluster
echo ""
