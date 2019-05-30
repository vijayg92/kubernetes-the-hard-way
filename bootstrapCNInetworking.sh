#!/bin/bash
set -e

function __verifyClusterStatus() {
  kubectl get nodes
  if [ $rc -ne 0 ]; then
    echo "Error: Unable to get Kubernetes Cluster Status!!"
    exit 1
  fi
}

function __deployWeaveNet() {
  k8sVersion=$(kubectl version | base64 | tr -d '\n')
  kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=${k8sVersion}&env.IPALLOC_RANG=10.200.0.0/16"
  if [ $rc -ne 0 ]; then
    echo "Error: Unable to Deploy Weave Networking!!"
    exit 1
  fi
  echo ""
  kubectl get pods -n kube-system
}

function __validateCNIdeployment() {
    echo ""
    echo "Deploying Nginx Contianer to Validate Weave CNI Networking!!"
    echo ""
      cat <<- EOF | kubectl apply -f -
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: nginx
      spec:
        selector:
          matchLabels:
            run: nginx
        replicas: 2
        template:
          metadata:
            labels:
              run: nginx
          spec:
            containers:
            - name: nginx
              image: nginx
              ports:
              - containerPort: 80
      EOF
      echo ""
      kubectl get pods
      echo ""
      echo "Creating Service for Nginx Deployment"
      echo ""
      kubectl expose deployment/nginx
      echo ""

      echo "Deploying a test pod to validate Nginx configs"
      echo ""
      kubectl run busybox --image=radial/busyboxplus:curl --command -- sleep 3600
      echo ""
      POD_NAME=$(kubectl get pods -l run=busybox -o jsonpath="{.items[0].metadata.name}")
      POD_IP=$(kubectl get ep nginx | grep nginx | awk '{print $2}' | awk -F ',' '{print $1}')
      STATUS_CODE=$(kubectl exec ${POD_NAME} -- curl -I ${POD_IP})
      if [ ${STATUS_CODE} -ne 200 ]; then
        echo "Error: Unable to Verify Weave Networking!!"
        exit 1
      fi
      echo ""
      SVC_IP=$(kubectl get svc nginx | awk '{print $3}')
      STATUS_CODE=$(kubectl exec ${POD_NAME} -- curl -I ${SVC_IP})
      if [ ${STATUS_CODE} -ne 200 ]; then
        echo "Error: Unable to Verify Weave Networking!!"
        exit 1
      fi
      echo ""
      echo "Successfully Validated Weave Deployment!!"
      echo ""
}

## Main Function ##
__verifyClusterStatus
__deployWeaveNet
__validateCNIdeployment
