#!/bin/bash

function main() {
  if [ ! -f /tmp/cfssl_linux-amd64 ]; then
    wget -P /tmp --timestamping https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
    sudo chmod +x /tmp/cfssl_linux-amd64 cfssljson_linux-amd64
    sudo cp /tmp/cfssl_linux-amd64 /usr/local/bin/cfssl
  fi

  if [ ! -f /tmp/cfssljson_linux-amd64 ]; then
    wget -P /tmp --timestamping https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
    sudo chmod +x /tmp/cfssljson_linux-amd64
    sudo cp /tmp/cfssljson_linux-amd64 /usr/local/bin/cfssljson
  fi
  cfssl version || exit 1

  if [ ! -f /tmp/kubectl ]; then
    wget -P /tmp --timestamping https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kubectl
    sudo chmod +x /tmp/kubectl
    sudo cp /tmp/kubectl /usr/local/bin/
  fi
  kubectl version --client || exit 1
  
  return $?
}
