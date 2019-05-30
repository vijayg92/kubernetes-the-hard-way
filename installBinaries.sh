#!/bin/bash
set -e

function main() {
  echo ""
  if [ ! -f /usr/local/bin/cfssl ]; then
    wget -P /tmp --timestamping https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
    chmod +x /tmp/cfssl_linux-amd64
    mv /tmp/cfssl_linux-amd64 /usr/local/bin/cfssl
  fi

  echo ""
  if [ ! -f /usr/local/bin/cfssljson ]; then
    wget -P /tmp --timestamping https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
    chmod +x /tmp/cfssljson_linux-amd64
    mv /tmp/cfssljson_linux-amd64 /usr/local/bin/cfssljson
  fi
  cfssl version || exit 1

  echo ""
  if [ ! -f /usr/local/bin/kubectl ]; then
    wget -P /tmp --timestamping https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kubectl
    chmod +x /tmp/kubectl
    cp /tmp/kubectl /usr/local/bin/
  fi

  echo ""
  kubectl version --client || exit 1
  echo ""
}
