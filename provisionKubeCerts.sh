#!/bin/bash
set -e 

function __provisionCACerts() {
  echo "Provisioning Kubernetes CA Certificates"
  jq -n '{"signing": {"default": {"expiry": "8760h"},"profiles": {"kubernetes": {"usages": ["signing", "key encipherment", "server auth", "client auth"],"expiry": "8760h"}}}}' > ca-config.json

  jq -n --arg C $C --arg L $L --arg O $O --arg OU $OU --arg ST $ST \
      '{"CN": "Kubernetes","key": {"algo": "rsa","size": 2048},"names": [{"C": $C,"L": $L,"O": $O,"OU": $OU,"ST": $ST}]}' > ca-csr.json

  cfssl gencert -initca ca-csr.json | cfssljson -bare ca
  echo "Successfully Provisioned CA Certificates"
  echo ""
}

function __provisionAdminCerts() {
  echo "Provisioning Kubernetes Admin Certificates"
  jq -n --arg C $C --arg L $L --arg ST $ST \
      '{"CN": "admin","key": {"algo": "rsa","size": 2048},"names": [{"C": $C,"L": $L,"O": "system:masters","OU": "Kubernetes The Hard Way","ST": $ST}]}' > admin-csr.json

  cfssl gencert \
    -ca=./ca.pem \
    -ca-key=./ca-key.pem \
    -config=./ca-config.json \
    -profile=kubernetes \
    ./admin-csr.json | cfssljson -bare admin
  echo "Successfully Provisioned Admin Certificates"
  echo ""
}

function __provisionControllerCerts() {
  echo "Provisioning Kubernetes Controller Certificates"
  jq -n --arg C $C --arg L $L --arg O $O --arg OU $OU --arg ST $ST \
    '{"CN": "system:kube-controller-manager","key": {"algo": "rsa","size": 2048},"names": [{"C": $C,"L": $L,"O": "system:kube-controller-manager","OU": "Kubernetes The Hard Way","ST": $ST}]}' > kube-controller-manager-csr.json

  cfssl gencert \
    -ca=./ca.pem \
    -ca-key=./ca-key.pem \
    -config=./ca-config.json \
    -profile=kubernetes \
    ./kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager
  echo "Successfully Provisioned Controller Certificates"
  echo ""
}

function __provisionProxyClientCerts() {
  echo "Provisioning Kubernetes Proxy Client Certificates"
  jq -n --arg C $C --arg L $L --arg OU $OU --arg ST $ST \
    '{"CN": "system:kube-proxy","key": {"algo": "rsa","size": 2048},"names": [{"C": $C,"L": $L,"O": "system:node-proxier","OU": "Kubernetes The Hard Way","ST": $ST}]}' > kube-proxy-csr.json

  cfssl gencert \
    -ca=./ca.pem \
    -ca-key=./ca-key.pem \
    -config=./ca-config.json \
    -profile=kubernetes \
    ./kube-proxy-csr.json | cfssljson -bare kube-proxy
  echo "Successfully Provisioned Kebe Proxy Client Certificates"
  echo ""
}

function __provisionSchedulerCerts() {
  echo "Provisioning Kubernetes Scheduler Certificates"
  jq -n --arg C $C --arg L $L --arg ST $ST \
    '{"CN": "system:kube-scheduler","key": {"algo": "rsa","size": 2048},"names": [{"C": $C,"L": $L,"O": "system:kube-scheduler","OU": "Kubernetes The Hard Way","ST": $ST}]}' > kube-scheduler-csr.json

  cfssl gencert \
    -ca=./ca.pem \
    -ca-key=./ca-key.pem \
    -config=./ca-config.json \
    -profile=kubernetes \
    ./kube-scheduler-csr.json | cfssljson -bare kube-scheduler
  echo "Successfully Provisioned Scheduler Certificates"
  echo ""
}

function __provisionAPICerts() {
  echo "Provisioning Kubernetes API Certificates"
  jq -n --arg C $C --arg L $L --arg ST $ST \
    '{"CN": "kubernetes","key": {"algo": "rsa","size": 2048},"names": [{"C": $C,"L": $L,"O": "Kubernetes","OU": "Kubernetes The Hard Way","ST": $ST}]}' > kubernetes-csr.json

  cfssl gencert \
    -ca=./ca.pem \
    -ca-key=./ca-key.pem \
    -config=./ca-config.json \
    -hostname=${API_CERT_HOSTNAMES} \
    -profile=kubernetes \
    ./kubernetes-csr.json | cfssljson -bare kubernetes
  echo "Successfully Provisioned Kubernetes API Certificates"
  echo ""
}

function __provisionSAKey() {
  echo "Provisioning Kubernetes Service Account Key"
  jq -n --arg C $C --arg L $L --arg ST $ST \
      '{"CN": "service-accounts","key": {"algo": "rsa","size": 2048},"names": [{"C": $C,"L": $L,"O": "Kubernetes","OU": "Kubernetes The Hard Way","ST": $ST}]}' > service-account-csr.json

  cfssl gencert \
    -ca=./ca.pem \
    -ca-key=./ca-key.pem \
    -config=./ca-config.json \
    -profile=kubernetes \
    ./service-account-csr.json | cfssljson -bare service-account
  echo "Successfully Provisioned Service Account Key"
  echo ""
}

function __provisionClientCerts() {
  echo "Provisioning Kubernetes Client Certificates"

  for worker in "${KUBE_WORKERS[@]}"; do
    jq -n --arg C $C --arg L $L --arg ST $ST --arg worker $worker \
    '{"CN": "system:node:$worker","key": {"algo": "rsa","size": 2048},"names": [{"C": $C,"L": $L,"O": "system:nodes","OU": "Kubernetes The Hard Way","ST": $ST}]}' > ${worker}-csr.json
    worker_ip=`ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -l root ${worker} 'hostname -I'`

    cfssl gencert \
      -ca=./ca.pem \
      -ca-key=./ca-key.pem \
      -config=./ca-config.json \
      -hostname=${worker},${worker_ip} \
      -profile=kubernetes \
      ${worker}-csr.json | cfssljson -bare ${worker}
  done
  echo "Successfully Provisioned Kubernetes Client Certificates"
  echo ""
}

function __distributeCertsFilesOnWorkers() {

  echo "Distributing Certificates on Kubernetes Worker Nodes"
  for worker in "${KUBE_WORKERS[@]}"; do
    scp ./ca.pem ${worker}-key.pem ${worker}.pem root@${worker}:~/
    if [ $? -ne 0 ]; then
      echo "Failed to copy certs on ${worker} node"
      exit 1
    fi
  done
  echo "Successfully Distributed Certificates on Kubernetes Worker Nodes"
  echo ""
}


function __distributeCertsFilesOnController() {

  echo "Distributing Certificates on Kubernetes Master (Controller) Nodes"
  for controller in "${CONTROL_PLANES[@]}"; do
    scp ./ca.pem ./ca-key.pem ./kubernetes-key.pem ./kubernetes.pem ./service-account-key.pem ./service-account.pem root@${controller}:~/
    if [ $? -ne 0 ]; then
      echo "Failed to copy configs to ${controller} node"
      exit 1
    fi
  done
  echo "Successfully Distributed Certificates on Kubernetes Master Nodes"
  echo ""
}

function main() {
  getWorkingDirectory=$(pwd)
  source ./clusterConfigs.txt
  cd ${LOCAL_KUBE_CONFIG_PATH}
  __provisionCACerts
  __provisionAdminCerts
  __provisionControllerCerts
  __provisionProxyClientCerts
  __provisionSchedulerCerts
  __provisionAPICerts
  __provisionSAKey
  __provisionClientCerts
  __distributeCertsFilesOnWorkers
  __distributeCertsFilesOnController
  cd ${getWorkingDirectory}
}
