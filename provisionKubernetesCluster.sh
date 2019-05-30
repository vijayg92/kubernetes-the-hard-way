#!/bin/bash
set -e

function __bootstrapETCDCluster() {
	echo ""
	for controller in "${CONTROL_PLANES[@]}"; do
		echo "Provisioning ETCD Node: ${controller}"
		scp ./bootstrapETCDNodes.sh ./clusterConfigs.txt root@${controller}:~/
		ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -l root ${controller} "bash ./bootstrapETCDNodes.sh"
		if [ $? -ne 0 ]; then
			echo "Failed to Bootstrap ETCD ${controller} node"
			exit 1
		fi
	done
	echo "Successfully Bootstrapped ETCD Cluster"
	echo ""
}

function __bootstrapKubeController() {
	echo ""
	for controller in "${CONTROL_PLANES[@]}"; do
		echo "Provisioning Kubernetes Controller Node: ${controller}"
		scp ./bootstrapControlpanes.sh ./clusterConfigs.txt root@${controller}:~/
		ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -l root ${controller} "bash ./bootstrapControlpanes.sh"
		if [ $? -ne 0 ]; then
			echo "Failed to Bootstrap Kube Controller ${controller} node"
			exit 1
		fi
	done
	echo "Successfully Bootstrapped Kubernetes Controller Nodes"
	echo ""
}

function __bootstrapKubeAPILoadBalancer() {
	echo ""
	echo "Provisioning Kubernetes API Load Balancer on node : ${KUBE_API_LB}"
	scp ./bootstrapAPILoadBalancer.sh root@${KUBE_API_LB}:~/
	echo ""
	ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -l root ${KUBE_API_LB} "bash ./bootstrapAPILoadBalancer.sh CONTROL_PLANES_IPS[*]"
	if [ $? -ne 0 ]; then
		echo "Failed to Bootstrap Kubernetes API LB ${KUBE_API_LB}"
		exit 1
	fi
	echo "Successfully Bootstrapped Kubernetes API LB"
	echo ""
}

function __provisionKubeWorker() {
	echo ""
	for worker in "${KUBE_WORKERS[@]}"; do
		echo "Provisioning ETCD ${controller} node"
		scp ./bootstrapWorkerNodes.sh root${controller}:~/
		ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -l root ${worker} "bash ./bootstrapWorkerNodes.sh"
		if [ $? -ne 0 ]; then
			echo "Failed to Bootstrap ETCD ${controller} node"
			exit 1
		fi
	done
	echo ""
	echo "Successfully Bootstrapped Kuberneted Worker Nodes!!"
	echo ""
}

function main() {
	source ./clusterConfigs.txt
	__bootstrapETCDCluster
	__bootstrapKubeController
	__bootstrapKubeAPILoadBalancer
}
