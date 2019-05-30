#!/bin/bash
set -e

KUBE_WORKER_HOSTNAME=$(hostname -f)
KUBE_WORKER_IP=$(hostname -I | awk '{print $1}')

function __installBinaries() {

 	echo ""
	  rpm --query socat || yum install -y socat
	  rpm --query conntrack || yum install -y conntrack
	  rpm --query ipset || yum install -y ipset
	echo ""

	echo "Validating Config Directories"
	echo ""
	if [ ! -d "/etc/cni/net.d" ]; then
		mkdir -p /etc/cni/net.d
	fi

	if [ ! -d "/opt/cni/bin" ]; then
		mkdir -p /opt/cni/bin
	fi

	if [ ! -d "/var/lib/kubelet" ]; then
		mkdir -p /var/lib/kubelet
	fi

	if [ ! -d "/var/lib/kube-proxy" ]; then
		mkdir -p /var/lib/kube-proxy
	fi

	if [ ! -d "/var/lib/kubernetes" ]; then
		mkdir -p /var/lib/kubernetes
	fi

	if [ ! -d "/var/run/kubernetes" ]; then
		mkdir -p /var/run/kubernetes
	fi

  	echo "Validating required binaries"
	echo ""
  	if [ ! -f "/usr/local/bin/crictl" ]; then
	  	wget -P /tmp --timestamping https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.12.0/crictl-v1.12.0-linux-amd64.tar.gz
	  	tar -xvf /tmp/crictl-v1.12.0-linux-amd64.tar.gz -C /usr/local/bin/
	  	chmod +x /usr/local/bin/crictl
	fi

	echo ""
	if [ ! -f "/usr/local/bin/runsc" ]; then
	  	wget -P /tmp --timestamping https://storage.googleapis.com/kubernetes-the-hard-way/runsc-50c283b9f56bb7200938d9e207355f05f79f0d17
	  	mv /tmp/runsc-50c283b9f56bb7200938d9e207355f05f79f0d17 /usr/local/bin/runsc
	  	chmod +x /usr/local/bin/runsc
	fi

	echo ""
	if [ ! -f "/usr/local/bin/runc" ]; then
	  	wget -P /tmp --timestamping https://github.com/opencontainers/runc/releases/download/v1.0.0-rc5/runc.amd64
	  	mv /tmp/runc.amd64 /usr/local/bin/runc
	  	chmod +x /usr/local/bin/runc
	fi

	echo ""
	if [ ! -d "/opt/cni/bin/flannel" ]; then
	  	wget -P /tmp --timestamping https://github.com/containernetworking/plugins/releases/download/v0.6.0/cni-plugins-amd64-v0.6.0.tgz
	  	tar -xvf /tmp/cni-plugins-amd64-v0.6.0.tgz -C /opt/cni/bin/
	fi

	echo ""
	if [ ! -f "/root/bin/containerd" ]; then
	  	wget -P /tmp --timestamping https://github.com/containerd/containerd/releases/download/v1.2.0-rc.0/containerd-1.2.0-rc.0.linux-amd64.tar.gz
	  	tar -xvf /tmp/containerd-1.2.0-rc.0.linux-amd64.tar.gz -C /root/
	fi

	echo ""
	if [ ! -f "/usr/local/bin/kubectl" ]; then
	  	wget -P /tmp --timestamping https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kubectl
		mv /tmp/kubectl /usr/local/bin/kubectl
	  	chmod +x /usr/local/bin/kubectl
	fi

	echo ""
	if [ ! -f "/usr/local/bin/kube-proxy" ]; then
	  	wget -P /tmp --timestamping https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kube-proxy
	  	mv /tmp/kube-proxy /usr/local/bin/kube-proxy
	  	chmod +x /usr/local/bin/kube-proxy
	fi

	echo ""
	if [ ! -f "/usr/local/bin/kubelet" ]; then
	  	wget -P /tmp --timestamping https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kubelet
	  	mv /tmpkubelet /usr/local/bin/kubelet
	  	chmod +x /usr/local/bin/kubelet
	fi
	echo ""

	echo "Successfully validated configs directories and required binaries!!!"
}

function __configureContainerd() {

	if [ ! -d "/etc/containerd" ]; then
		mkdir -p /etc/containerd
	fi

	if [ ! -f "/etc/containerd/config.toml" ]; then
		cat <<- EOF | tee /etc/containerd/config.toml
		[plugins]
			[plugins.cri.containerd]
				snapshotter = "overlayfs"
				[plugins.cri.containerd.default_runtime]
					runtime_type = "io.containerd.runtime.v1.linux"
					runtime_root = ""
				[plugin.cri.containerd.untrusted_workload_runtime]
					runtime_type = "io.containerd.runtime.v1.linux"
					runtime_engine = "/usr/local/bin/runsc"
					runtime_root = "/run/containerd/runsc"
		EOF
	fi

	if [ ! -f "/etc/systemd/system/containerd.service" ]; then
		cat <<- EOF | tee /etc/systemd/system/containerd.service
		[Unit]
		Description=containerd container runtime
		Documentation=https://containerd.io
		After=network.target

		[Service]
		ExecStartPre=/sbin/modprobe overlay
		ExecStart=/bin/containerd
		Restart=always
		RestartSec=5
		Delegate=yes
		KillMode=process
		OOMScoreAdjust=-999
		LimitNOFILE=1048576
		LimitNPROC=infinity
		LimitCORE=infinity

		[Install]
		WantedBy=multi-user.target
		EOF
	fi
}

function __configureKublet() {
	echo ""
	echo "Copying kubeconfig & certfiles"
	echo ""
	if [ ! -d "/var/lib/kubernetes/" ]; then
		mv ${KUBE_WORKER_HOSTNAME}-key.pem ${KUBE_WORKER_HOSTNAME}.pem /var/lib/kubelet/
	    mv ${KUBE_WORKER_HOSTNAME}.kubeconfig /var/lib/kubelet/kubeconfig
	    mv ca.pem /var/lib/kubernetes/
	fi

	echo "Creating kubelet-config.yaml!!"
	echo ""
	if [ ! -f "/var/lib/kubelet/kubelet-config.yaml" ]; then
		cat <<- EOF | sudo tee /var/lib/kubelet/kubelet-config.yaml
		kind: KubeletConfiguration
		apiVersion: kubelet.config.k8s.io/v1beta1
		authentication:
		  anonymous:
		    enabled: false
		  webhook:
		    enabled: true
		  x509:
		    clientCAFile: "/var/lib/kubernetes/ca.pem"
		authorization:
		  mode: Webhook
		clusterDomain: "cluster.local"
		clusterDNS:
		  - "10.32.0.10"
		podCIDR: "${POD_CIDR}"
		resolvConf: "/run/systemd/resolve/resolv.conf"
		runtimeRequestTimeout: "15m"
		tlsCertFile: "/var/lib/kubelet/${KUBE_WORKER_HOSTNAME}.pem"
		tlsPrivateKeyFile: "/var/lib/kubelet/${KUBE_WORKER_HOSTNAME}-key.pem"
		EOF
	fi

	echo "Creating kubelet.service unit file for kubelet!!"
	echo ""
	if [ ! -f /etc/systemd/system/kubelet.service ]; then
		cat <<-EOF | sudo tee /etc/systemd/system/kubelet.service
		[Unit]
		Description=Kubernetes Kubelet
		Documentation=https://github.com/kubernetes/kubernetes
		After=containerd.service
		Requires=containerd.service

		[Service]
		ExecStart=/usr/local/bin/kubelet \\
		  --config=/var/lib/kubelet/kubelet-config.yaml \\
		  --container-runtime=remote \\
		  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
		  --image-pull-progress-deadline=2m \\
		  --kubeconfig=/var/lib/kubelet/kubeconfig \\
		  --network-plugin=cni \\
		  --register-node=true \\
		  --v=2 \\
		  --hostname-override=${KUBE_WORKER_HOSTNAME} \\
		  --allow-privileged=true

		Restart=on-failure
		RestartSec=5

		[Install]
		WantedBy=multi-user.target
		EOF
	fi
	echo ""
	echo "Successfully configured Kubelet on Worker Nodes!!"
	echo ""
}

function __configureKubeProxy() {

	echo ""
	if [ !-f /var/lib/kube-proxy/kubeconfig ]; then
		mv ./kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig
	fi

	echo "Validating kube-proxy-config.yaml"
	echo ""
	if [ !-f /var/lib/kube-proxy/kube-proxy-config.yaml ]; then
		cat <<- EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
		kind: KubeProxyConfiguration
		apiVersion: kubeproxy.config.k8s.io/v1alpha1
		clientConnection:
		  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
		mode: "iptables"
		clusterCIDR: "10.200.0.0/16"
		EOF
	fi


	echo "Validating kube-proxy.service"
	echo ""
	if [ !-f /etc/systemd/system/kube-proxy.service ]; then
		cat <<-EOF | sudo tee /etc/systemd/system/kube-proxy.service
		[Unit]
		Description=Kubernetes Kube Proxy
		Documentation=https://github.com/kubernetes/kubernetes

		[Service]
		ExecStart=/usr/local/bin/kube-proxy \\
		  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
		Restart=on-failure
		RestartSec=5

		[Install]
		WantedBy=multi-user.target
		EOF
	fi

  echo ""
  echo "net.ipv4.conf.all.forwarding=1" | tee -a /etc/sysctl.conf
  sysctl -p
	echo ""
	echo "Starting Kubelet & Kube-Proxy Services"
	systemctl daemon-reload
	echo ""
	systemctl enable containerd kubelet kube-proxy
	echo ""
	systemctl start containerd kubelet kube-proxy
	echo "Successfully configured Kubelet on Kubernetes Workers!!"
	echo ""
}

## Main Function ##
__installBinaries
__configureContainerd
__configureKublet
__configureKubeProxy
