# Kubernetes the hard way

*A simple & real quick deployment of Kubernetes HA Cluster based on "Kubernetes the Hard Way"*

## Architecture

Kubernetes Control Plane (Masters) : 2
Kubernetes Worker Nodes (Minions) : 3
Kubernetes API LoadBalancer : 1
Provisoner Host (Local Machine): 1

## Prerequisites

1. You must have root access on all the nodes : `(Masters, Workers, API LB Server and Local Host).`
2. A keyless authentication must be set from Previsioner Host (Local Host) to all other Kubernetes nodes (`Kubernetes Masters, Workers, and API LB Node.`
3. Kubernetes Controllers details must be updated in `clusterConfigs.txt`.
4. Kubernetes API LoadBalancer details must be updated in `clusterConfigs.txt`.
5. Kubernetes Workers details must be updated in `clusterConfigs.txt`.
6. Kubernetes Certificates details must be updated in `clusterConfigs.txt`.
7. Before initiating the deployment of the cluster, make sure to run `initialChecks.sh` script to validate prerequisites.

## Configuration

This is the main configuration file to deploy the whole cluster. It contains Kubernetes Nodes Details, Kubernetes Certificates Details, Kubernetes Controller Public IP, Local Host (Workstation) Details, Kubernetes ETCD Cluster Configs and so forth.

```bash
# ---------------------------------------------------------------- #
# ------------- Kubernetes Master Nodes Configs ------------------ #
# ---------------------------------------------------------------- #
CONTROL_PLANES=(kube-master01 kube-master02)
CONTROL_PLANES_IPS=(10.74.250.10 10.74.254.170)
ETCD_CLUSTER_CONFIGS="kube-master01=https://10.74.250.10:2380,kube-master02=https://10.74.254.170:2380"
# -----------------------------------------------------------------#
# ---------- Kubernetes API Load Balancer Configs -----------------#
# -----------------------------------------------------------------#
KUBE_API_LB="kube-api-lb"
API_LB_IP=(10.74.255.110)
API_CERT_HOSTNAMES="10.74.250.10,kube-master01.gsslab.pnq2.redhat.com,10.74.254.170,kube-master02.gsslab.pnq2.redhat.com,127.0.0.1,kubernetes.default"
# -----------------------------------------------------------------#
# ------------- Kubernetes Worker Nodes Configs -------------------#
# -----------------------------------------------------------------#
KUBE_WORKERS=(kube-worker01 kube-worker02 kube-worker03)
KUBE_WORKERS_IPS=(10.74.253.199 10.74.250.141 10.74.249.90)
# -----------------------------------------------------------------#
# ---------------- Provisoner Host Configs ------------------------#
# -----------------------------------------------------------------#
LOCAL_HOST="desktop.vgosai.redhat.com.users.ipa.redhat.com"
LOCAL_HOST_IP="10.65.144.128"
LOCAL_KUBE_CONFIG_PATH=/tmp/kubernetes
# -----------------------------------------------------------------#
# ------------ Kubernetes Certificates Details --------------------#
# -----------------------------------------------------------------#
C=IN
L=DELHI
O=DevOps
OU=ENG
ST=NEWDELHI
```
Kindly make sure to update the configuration in `clusterConfigs.txt` prior to deploy.


## Usage
1. `clusterConfigs.txt`: *Stores Kubernetes Cluster Configurations*
2. `checkPrerequisites.sh`:  *Script to run initial checks*
3. `installBinaries.sh`: *Installs all the required binaries.*
4. `provisionCerts.sh` : *Provisions of all the required certificates.*
5. `generateKubeConfigs.sh`: *Generates all the required Kubernetes Configuration files.*
6. `bootstrapControlpanes.sh`: *Bootstraps Kubernetes Control panes (masters).*
7. `bootstrapEtcd.sh`: *Bootstraps ETCD cluster.*
8. `bootstrapWorkerNodes.sh`: *Bootstraps Kubernetes nodes.*
9. `validateCluster.sh`: *Validate deployment of the cluster.*
10. `deployKubernetesTheHardway.sh`: *This is the main script which sequentially performs all the above steps to deploy the cluster in a hard way.*

## Installation

1. First you need to clone the repository:

```bash
git clone https://github.com/vijayg92/kubernetes-the-hard-way.git
cd kubernetes-the-hard-way
```

2. Then, run `checkPrerequisites.sh` script to validate prerequisites:

```bash
./checkPrerequisites.sh
```

3. If step 2 works fine then only deploy the cluster by running `deploy_kubernetes_the_hard_way.sh` script:

```bash
./deployKubernetesTheHardway.sh
```

4. Finally validation the cluster.

```bash
./validateCluster.sh
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
[GPLv3](https://www.gnu.org/licenses/)
