#!/bin/bash
set -e

### Global Variable ###
KUBE_CONTROLLER_VERSION=1.12.0
ETCD_SERVER_ENDPOINTS=$(grep -i ETCD_CLUSTER_CONFIGS ./clusterConfigs.txt)
KUBE_CONTROLLER_IP=$(hostname -i)

function __installRequiredBinaries() {

  if [ ! -f /usr/local/bin/kube-apiserver ]; then
    wget -P /tmp --timestamping "https://storage.googleapis.com/kubernetes-release/release/v${KUBE_CONTROLLER_VERSION}/bin/linux/amd64/kube-apiserver"
    chmod +x /tmp/kube-apiserver && mv /tmp/kube-apiserver /usr/local/bin/
  fi

  if [ ! -f /usr/local/bin/kube-controller-manager ]; then
    wget -P /tmp --timestamping "https://storage.googleapis.com/kubernetes-release/release/v${KUBE_CONTROLLER_VERSION}/bin/linux/amd64/kube-controller-manager"
    chmod +x /tmp/kube-controller-manager && mv /tmp/kube-controller-manager /usr/local/bin/
  fi

  if [ ! -f /usr/local/bin/kube-scheduler ]; then
    wget -P /tmp --timestamping "https://storage.googleapis.com/kubernetes-release/release/v${KUBE_CONTROLLER_VERSION}/bin/linux/amd64/kube-scheduler"
    chmod +x /tmp/kube-scheduler && mv /tmp/kube-scheduler /usr/local/bin/
  fi

  if [ ! -f /usr/local/bin/kubectl ]; then
    wget -P /tmp --timestamping "https://storage.googleapis.com/kubernetes-release/release/v${KUBE_CONTROLLER_VERSION}/bin/linux/amd64/kubectl"
    chmod +x /tmp/kubectl && mv /tmp/kubectl /usr/local/bin/
  fi
}

function __bootstrapClusterComponents() {

  if [ ! -d /etc/kubernetes/config ]; then
    mkdir -p /etc/kubernetes/config
  fi

  if [ ! -d /var/lib/kubernetes ]; then
    mkdir -p /var/lib/kubernetes
    mv ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem service-account-key.pem service-account.pem encryption-config.yaml /var/lib/kubernetes/
    mv kube-controller-manager.kubeconfig kube-scheduler.kubeconfig /var/lib/kubernetes/
  fi

  if [ ! -f /etc/systemd/system/kube-apiserver.service ]; then
    cat <<- EOF | tee /etc/systemd/system/kube-apiserver.service
    [Unit]
    Description=Kubernetes API Server
    Documentation=https://github.com/kubernetes/kubernetes

    [Service]
    ExecStart=/usr/local/bin/kube-apiserver \\
      --advertise-address=${KUBE_CONTROLLER_IP} \\
      --allow-privileged=true \\
      --apiserver-count=3 \\
      --audit-log-maxage=30 \\
      --audit-log-maxbackup=3 \\
      --audit-log-maxsize=100 \\
      --audit-log-path=/var/log/audit.log \\
      --authorization-mode=Node,RBAC \\
      --bind-address=0.0.0.0 \\
      --client-ca-file=/var/lib/kubernetes/ca.pem \\
      --enable-admission-plugins=Initializers,NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
      --enable-swagger-ui=true \\
      --etcd-cafile=/var/lib/kubernetes/ca.pem \\
      --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
      --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
      --etcd-servers=${ETCD_SERVER_ENDPOINTS} \\
      --event-ttl=1h \\
      --experimental-encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
      --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
      --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
      --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
      --kubelet-https=true \\
      --runtime-config=api/all \\
      --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
      --service-cluster-ip-range=10.32.0.0/24 \\
      --service-node-port-range=30000-32767 \\
      --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
      --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
      --v=2
    Restart=on-failure
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
    EOF
  fi

  if [ ! -f /etc/systemd/system/kube-controller-manager.service ]; then
    cat <<- EOF | sudo tee /etc/systemd/system/kube-controller-manager.service
    [Unit]
    Description=Kubernetes Controller Manager
    Documentation=https://github.com/kubernetes/kubernetes

    [Service]
    ExecStart=/usr/local/bin/kube-controller-manager \\
      --address=0.0.0.0 \\
      --cluster-cidr=10.200.0.0/16 \\
      --cluster-name=kubernetes \\
      --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
      --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
      --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
      --leader-elect=true \\
      --root-ca-file=/var/lib/kubernetes/ca.pem \\
      --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
      --service-cluster-ip-range=10.32.0.0/24 \\
      --use-service-account-credentials=true \\
      --v=2
    Restart=on-failure
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
    EOF
  fi

  if [ ! -f /etc/kubernetes/config/kube-scheduler.yaml ]; then
    cat <<- EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml
    apiVersion: componentconfig/v1alpha1
    kind: KubeSchedulerConfiguration
    clientConnection:
      kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
    leaderElection:
      leaderElect: true
    EOF
  fi

  if [ ! -f /etc/systemd/system/kube-scheduler.service ]; then
    cat <<- EOF | tee /etc/systemd/system/kube-scheduler.service
    [Unit]
    Description=Kubernetes Scheduler
    Documentation=https://github.com/kubernetes/kubernetes

    [Service]
    ExecStart=/usr/local/bin/kube-scheduler \\
      --config=/etc/kubernetes/config/kube-scheduler.yaml \\
      --v=2
    Restart=on-failure
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
    EOF
  fi

  echo ""
  systemctl daemon-reload
  echo "Starting kube-apiserver, kube-controller-manager & kube-scheduler services"
  systemctl enable kube-apiserver kube-controller-manager kube-scheduler
  systemctl start kube-apiserver kube-controller-manager kube-scheduler
  echo ""

  echo "Validting Kubernetes Component Status"
  kubectl get componentstatues --kubeconfig admin.kubeconfig
  echo ""

}

function __configureHealthChecks() {

  echo ""
  echo "Validting Nginx Installation"
  echo ""
  rpm --query nginx || yum install -y nginx

  if [ ! -f /etc/nginx/sites-available/kubernetes.default.svc.cluster.local ]; then
    cat <<- EOF | tee /etc/nginx/sites-available/kubernetes.default.svc.cluster.local
      server {
        listen  80;
        server_name kubernetes.default.svc.cluster.local;

        location /healthz {
          proxy_pass  https://127.0.0.1:6443/healthz
          proxy_ssl_trusted_certificate /var/lib/kubernetes/ca.pem;
        }
      }
    EOF
    ln -s /etc/nginx/sites-available/kubernetes.default.svc.cluster.local /etc/nginx/sites-enabled
  fi

  echo "Starting Nginx Service"
  systemctl enable nginx
  systemctl start nginx
  echo ""
}

function __setupAuth() {

  if [ ! -f "./admin.kubeconfig" ]; then
    echo "Error : file admin.kubeconfig doesn't exist!!"
    exit 1
  fi

  echo""
  echo "Setting up authorization for Kubelet"
  echo""
  cat <<- EOF | kubectl apply --kubeconfig ./admin.kubeconfig -f -
  apiVersion: rbac.authorization.k8s.io/v1beta1
  kind: ClusterRole
  metadata:
    annotations:
      rbac.authorization.kubernetes.io/autoupdate: "true"
    labels:
      kubernetes.io/bootstrapping: rbac-defaults
    name: system:kube-apiserver-to-kubelet
  rules:
    - apiGroups:
        - ""
      resources:
        - nodes/proxy
        - nodes/stats
        - nodes/log
        - nodes/spec
        - nodes/metrics
      verbs:
        - "*"
  EOF

  echo""
  echo "Setting up an auth for User"
  echo""
  cat <<- EOF | kubectl apply --kubeconfig ./admin.kubeconfig -f -
  apiVersion: rbac.authorization.k8s.io/v1beta1
  kind: ClusterRoleBinding
  metadata:
    name: system:kube-apiserver
    namespace: ""
  roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: system:kube-apiserver-to-kubelet
  subjects:
    - apiGroup: rbac.authorization.k8s.io
      kind: User
      name: kubernetes
  EOF
  echo "Successfully Setup Authorization"
  echo ""
}

### Main Function ###
if [ $# -eq 0 ]; then
    echo""
    echo "Please Provide Valid Arguments!!"
    echo""
    echo "Usage: bootstrapControllerNode.sh KUBE_CONTROLLER_VERSION ETCD_SERVER_ENDPOINTS"
    exit 1
fi

__installRequiredBinaries
__bootstrapClusterComponents
__configureHealthChecks
__setupAuth
