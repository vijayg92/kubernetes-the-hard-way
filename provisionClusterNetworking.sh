#!/bin/bash
set -e

function __main() {
	echo ""
	for controller in "${CONTROL_PLANES[0]}"; do
		echo "Deplying Kubernetes CNI Networking on Node: ${controller}"
		scp .bootstrapCNInetworking.sh ./clusterConfigs.txt root@${controller}:~/
		ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -l root ${controller} "bash ./bootstrapCNInetworking.sh"
		if [ $? -ne 0 ]; then
			echo "Failed to Bootstrap Kube Controller ${controller} node"
			exit 1
		fi
	done
	echo "Successfully Deploy CNI Networking!!"
	echo ""
}
