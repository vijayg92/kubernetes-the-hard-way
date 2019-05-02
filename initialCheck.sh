#!/bin/bash

function _checkPrerequisites() {

  rpm --query wget || yum install -y wget
  rpm --query jq || yum install -y jq

  source ./clusterConfigs.txt
  echo "Validation Kubernetes Certificate Path"
  if [ ! -d ${kubeCertPath} ]; then
    mkdir -p ${kubeCertPath}
    cd ${kubeCertPath}
  fi

  for worker in "${kubeWorkers[@]}"; do
    echo "Trying to connect to Kubernetes ${worker} Node"
    ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -l root ${worker} 'hostname -f' &>/dev/null
    if [ "$?" -ne 0 ]; then
      echo "Unable to connect to ${worker}"; exit 1
    fi
    echo "Connection Succeeded"
  done

  for controller in "${kubeControllers[@]}"; do
    echo "Trying to connect to Kubernetes ${controller} Node"
    ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -l root ${controller} 'hostname -f' &>/dev/null
    if [ "$?" -ne 0 ]; then
      echo "Unable to connect to ${controller}"; exit 1
    fi
    echo "Connection Succeeded"
  done

  return $?
}
