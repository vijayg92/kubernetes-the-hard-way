#!/bin/bash

function main() {

for controller in "${kubeControllers[@]}"; do
	echo "Bootstraping ETCD ${controller} node"
	scp ./etcdSetup.sh root${controller}:~/
	ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -l root ${controller} "bash etcdSetup.sh 3.3.9 ${etcdClusterDetails}"
	if [ $? -ne 0 ]; then
		echo "Failed to Bootstrap ETCD ${controller} node"
		exit 1
	fi
done
echo ""
return $?
}