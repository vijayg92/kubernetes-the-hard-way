#!/bin/bash
set -e

function main() {
  rpm --query wget || yum install -y wget
  rpm --query jq || yum install -y jq
  source ./clusterConfigs.txt
    
  echo "Validating Host Machine Details"
  if [ `hostname -f` != "${hostMachine}" ]; then
      echo "Error - Kindly run this script from the local host ${hostMachine}"
      exit 1
  fi
  echo ""

  echo "Validation Kubernetes Certificate Path"
  if [ ! -d ${KubeConfigTempPath} ]; then
    mkdir -p ${KubeConfigTempPath}
    cd ${KubeConfigTempPath}
  fi
  echo ""
  
  for worker in "${kubeWorkers[@]}"; do
    echo "Trying to connect to Kubernetes ${worker} Node"
    ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -l root ${worker} 'hostname -f' &>/dev/null
    if [ "$?" -ne 0 ]; then
      echo "Unable to connect to ${worker}"
      exit 1
    fi
    echo "Connection Succeeded"
    echo ""
  done

  for controller in "${kubeControllers[@]}"; do
    echo "Trying to connect to Kubernetes ${controller} Node"
    ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -l root ${controller} 'hostname -f' &>/dev/null
    if [ "$?" -ne 0 ]; then
      echo "Unable to connect to ${controller}"
      exit 1
    fi
    echo "Connection Succeeded"
  done
  echo ""
  return $?
}
