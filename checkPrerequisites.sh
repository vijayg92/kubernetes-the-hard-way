#!/bin/bash
set -e

function main() {
  echo ""
  echo "Edge Case Checks"
  source ./clusterConfigs.txt

  echo ""
  echo "Check 1 : Kubernetes Master Configs"
  if [[ -z "${CONTROL_PLANES}" || -z "${CONTROL_PLANES_IPS}" || -z "${ETCD_CLUSTER_ENDPOINTS}" || -z "${ETCD_CLUSTER_CONFIGS}" || -z "${CLUSTER_CIDR}" || -z "${SERVICE_CLUSTER_CIDR}" || -z "${POD_CIDR}" ]]; then
      echo "Error: Kubernet Master Configs Must Be Specified!!"
      exit 1
  fi

  echo ""
  echo "Check 2 : Kubernetes API Load Balancer Configs"
  if [[ -z "${KUBE_API_LB}" || -z "${API_LB_IP}" || -z "${API_CERT_HOSTNAMES}" ]]; then
      echo "Error: Kubernetes API Load Balancer Configs Must Be Specified!!"
      exit 1
  fi

  echo ""
  echo "Check 3 : Kubernetes Worker Nodes Configs"
  if [[ -z "${KUBE_WORKERS}" || -z "${KUBE_WORKERS_IPS}" ]]; then
      echo "Error: Kubernet Worker Nodes Configs Must Be Specified!!"
      exit 1
  fi

  echo ""
  echo "Check 4 : Provisoner Host Configs"
  if [[ -z "${LOCAL_HOST}" || -z "${LOCAL_HOST_IP}" || -z "${LOCAL_KUBE_CONFIG_PATH}" ]]; then
      echo "Error: Kubernet Provisoner Host Configs Must Be Specified!!"
      exit 1
  fi

  echo ""
  echo "Check 5 : Kubernetes Certificates Details"
  if [[ -z "${C}" || -z "${L}" || -z "${O}" || -z "${OU}" || -z "${ST}" ]]; then
      echo "Error: Kubernetes Certificates Configs Must Be Specified!!"
      exit 1
  fi

  echo ""
  echo "Checking Master Configs"
  rpm --query wget || yum install -y wget
  rpm --query jq || yum install -y jq

  echo ""
  echo "Validating Provisioner (Host Machine) Configs : ${LOCAL_HOST}"
  if [ `hostname -f` != "${LOCAL_HOST}" ]; then
      echo "Error - Must be run on Provisioner Host ${LOCAL_HOST}"
      exit 1
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
      echo "Failed to Connect to ${worker}"
      exit 1
    fi
    echo "Successfully Validated Keyless Auth on ${worker}"
    echo ""
  done

  for controller in "${CONTROL_PLANES[@]}"; do
    echo "Validating Keyless Auth on Kubernetes Control Plane: ${controller} Node"
    ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -l root ${controller} 'hostname -f'; rc=$?
    if [ ${rc} -ne 0 ]; then
      echo "Failed to Connect to ${controller}"
      exit 1
    fi
    echo "Successfully Validated Keyless Auth on ${controller}"
    echo ""
  done

  echo "Validating Keyless Auth on Kubernetes API Load Balancer: ${KUBE_API_LB} Node"
  ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -l root ${KUBE_API_LB} 'hostname -f'; rc=$?
  if [ ${rc} -ne 0 ]; then
    echo "Failed to Connect to ${KUBE_API_LB}"
    exit 1
  fi
  echo "Successfully Validated Keyless Auth on ${KUBE_API_LB}"
  echo ""
}
