#!/bin/bash

function __generateKubeConfigs() {
	echo ""
	for worker in "${KUBE_WORKERS[@]}"; do

		echo "Generating KubeConfigs for ${worker} node"

		kubectl config set-cluster kubernetes-the-hard-way \
			--certificate-authority=ca.pem \
			--embed-certs=true \
			--server=https://${API_LB_IP}:6443 \
			--kubeconfig=${worker}.kubeconfig

		kubectl config set-credentials system:node:${worker} \
			--client-certificate=${worker}.pem \
			--client-key=${worker}-key.pem \
			--embed-certs=true \
			--kubeconfig=${worker}.kubeconfig

		kubectl config set-context default \
			--cluster=kubernetes-the-hard-way \
			--user=system:node:${worker} \
			--kubeconfig=${worker}.kubeconfig

		kubectl config use-context default --kubeconfig=${worker}.kubeconfig

		if [ ! -f "${worker}.kubeconfig" ]; then
			echo "Failed to generate kubernetes ${worker}.kubeconfig"
			exit 1
		fi
		echo ""
		scp ${worker}.kubeconfig kube-proxy.kubeconfig root@${worker}:~/
	done

	echo "Generating KubeProxy Configs"
	kubectl config set-cluster kubernetes-the-hard-way \
		--certificate-authority=ca.pem \
		--embed-certs=true \
		--server=https://${API_LB_IP}:6443 \
		--kubeconfig=kube-proxy.kubeconfig

	kubectl config set-credentials system:kube-proxy \
		--client-certificate=kube-proxy.pem \
		--client-key=kube-proxy-key.pem \
		--embed-certs=true \
		--kubeconfig=kube-proxy.kubeconfig

	kubectl config set-context default \
		--cluster=kubernetes-the-hard-way \
		--user=system:kube-proxy \
		--kubeconfig=kube-proxy.kubeconfig

	kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
	if [ ! -f "./kube-proxy.kubeconfig" ]; then
		echo "Failed to generate kubernetes kube-proxy.kubeconfig"
		exit 1
	fi
	echo ""

	echo "Generating KubeController Configs"
	kubectl config set-cluster kubernetes-the-hard-way \
		--certificate-authority=ca.pem \
		--embed-certs=true \
		--server=https://127.0.0.1:6443 \
		--kubeconfig=kube-controller-manager.kubeconfig

	kubectl config set-credentials system:kube-controller-manager \
		--client-certificate=kube-controller-manager.pem \
		--client-key=kube-controller-manager-key.pem \
		--embed-certs=true \
		--kubeconfig=kube-controller-manager.kubeconfig

	kubectl config set-context default \
		--cluster=kubernetes-the-hard-way \
		--user=system:kube-controller-manager \
		--kubeconfig=kube-controller-manager.kubeconfig

	kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig
	if [ ! -f "./kube-controller-manager.kubeconfig" ]; then
		echo "Failed to generate kubernetes kube-controller-manager.kubeconfig"
		exit 1
	fi
	echo ""

	echo "Generating KubeScheduler Configs"
	kubectl config set-cluster kubernetes-the-hard-way \
		--certificate-authority=ca.pem \
		--embed-certs=true \
		--server=https://127.0.0.1:6443 \
		--kubeconfig=kube-scheduler.kubeconfig

	kubectl config set-credentials system:kube-scheduler \
		--client-certificate=kube-scheduler.pem \
		--client-key=kube-scheduler-key.pem \
		--embed-certs=true \
		--kubeconfig=kube-scheduler.kubeconfig

	kubectl config set-context default \
		--cluster=kubernetes-the-hard-way \
		--user=system:kube-scheduler \
		--kubeconfig=kube-scheduler.kubeconfig

	kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig

	if [ ! -f "./kube-scheduler.kubeconfig" ]; then
		echo "Failed to generate kubernetes kube-scheduler.kubeconfig"
		exit 1
	fi
	echo ""

	echo "Generating Kubernetes Admin Configs"
	kubectl config set-cluster kubernetes-the-hard-way \
		--certificate-authority=ca.pem \
		--embed-certs=true \
		--server=https://127.0.0.1:6443 \
		--kubeconfig=admin.kubeconfig

	kubectl config set-credentials admin \
		--client-certificate=admin.pem \
		--client-key=admin-key.pem \
		--embed-certs=true \
		--kubeconfig=admin.kubeconfig

	kubectl config set-context default \
		--cluster=kubernetes-the-hard-way \
		--user=admin \
		--kubeconfig=admin.kubeconfig

	kubectl config use-context default --kubeconfig=admin.kubeconfig

	if [ ! -f "./admin.kubeconfig" ]; then
		echo "Failed to generate kubernetes admin.kubeconfig"
		exit 1
	fi
	echo ""
	echo "Config files have been sucessfully generated!!"
	echo ""
	return $?
}

function __distributeKubeWorkerConfigs() {
	for worker in "${KUBE_WORKERS[@]}"; do
		echo "Copying kubernetes worker configs to ${worker} node"
		scp ${worker}.kubeconfig kube-proxy.kubeconfig root@${worker}:~/
		if [ $? -ne 0 ]; then
			echo "Failed to copy configs to ${worker} node"
			exit 1
		fi
  	done
  	echo ""
  	return $?
}

function __generatingDataEncryptionConfig() {
	ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
	cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF
	if [ ! -f "./encryption-config.yaml" ]; then
		echo "Failed to generate encryption-config.yaml"
		exit 1
	fi
	echo ""
	return $?
}

function __distributeKubeMasterConfigs() {
	for controller in "${CONTROL_PLANES[@]}"; do
		echo "Copying kubernetes controller configs to ${controller} node"
		scp ./encryption-config.yaml ./admin.kubeconfig ./kube-controller-manager.kubeconfig ./kube-scheduler.kubeconfig root${controller}:~/
		if [ $? -ne 0 ]; then
			echo "Failed to copy configs to ${controller} node"
			exit 1
		fi
 	done
 	echo ""
 	return $?
}

function main() {
  source ./clusterConfigs.txt
  cd ${LOCAL_KUBE_CONFIG_PATH}
  __generateKubeConfigs
  __generatingDataEncryptionConfig
  __distributeKubeWorkerConfigs
  __distributeKubeMasterConfigs
}
