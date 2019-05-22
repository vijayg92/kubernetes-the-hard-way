#!/bin/bash
#set -e

function main() {
  echo ""
  rpm --query wget || yum install -y wget
  rpm --query jq || yum install -y jq
  source ./clusterConfigs.txt

  echo ""
  echo "Validating Cluster Provisioner (Host Machine) Details"
  if [ `hostname -f` != "${LOCAL_HOST}" ]; then
      echo "Error - Must be run on Provisioner Host ${LOCAL_HOST}" && exit 1
  fi

  echo ""
  if [ ! -d ${LOCAL_KUBE_CONFIG_PATH} ]; then
    mkdir -p ${LOCAL_KUBE_CONFIG_PATH}
    cd ${LOCAL_KUBE_CONFIG_PATH}
  fi

  for worker in "${KUBE_WORKERS[@]}"; do
    echo "Validating Keyless Auth on Kubernetes Worker : ${worker} Node"
    ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -l root ${worker} 'hostname -f'; rc=$?
    if [ ${rc} -ne 0 ]; then
      echo "Failed to Connect to ${worker}" && exit 1
    fi
    echo "Successfully Validated Keyless Auth on ${worker}"
    echo ""
  done

  for controller in "${CONTROL_PLANES[@]}"; do
    echo "Validating Keyless Auth on Kubernetes Control Plane: ${controller} Node"
    ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -l root ${controller} 'hostname -f'; rc=$?
    if [ ${rc} -ne 0 ]; then
      echo "Failed to Connect to ${controller}" && exit 1
    fi
    echo "Successfully Validated Keyless Auth on ${controller}"
    echo ""
  done

  echo "Validating Keyless Auth on Kubernetes API Load Balancer: ${KUBE_API_LB} Node"
  ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -l root ${KUBE_API_LB} 'hostname -f'; rc=$?
  if [ ${rc} -ne 0 ]; then
    echo "Failed to Connect to ${KUBE_API_LB}" && exit 1
  fi
  echo "Successfully Validated Keyless Auth on ${KUBE_API_LB}"
  echo ""

  return $?
}
