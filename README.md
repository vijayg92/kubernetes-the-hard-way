# Kubernetes the hard way

*A simple and real quick installation of Kubernetes the hard way*


## Prerequisites

1. You must have root access on all the nodes `(Master, Workers and Local Host).`
2. A keyless authentication must be set among `Kubernetes Nodes & Local Host.`
3. Kubernetes Controllers details must be updated in `clusterConfigs.txt.`
4. Kubernetes Workers details must be updated in `clusterConfigs.txt.`
5. Kubernetes Certificates details must be updated in `clusterConfigs.txt.`
6. Before installation of the cluster, make sure to run `initialChecks.sh.` script to validate all configs.

## Configuration

This is the main configuration file to deploy the whole cluster. It contains Kubernetes Nodes Details, Kubernetes Certificates Details, Kubernetes Controller Public IP, Local Host (Workstation) Details, Kubernetes ETCD Cluster Configs and so forth. 

```bash
##################################################################
################### Kubernetes Node Defination ###################
##################################################################
kubeControllers=(kube-master01)
kubeWorkers=(kube-worker01 kube-worker02)
kubePublicIP=(10.74.255.110)
etcdClusterDetails="kube-master01=https://10.240.0.10:2380"
##################################################################
############## Kubernetes Default Configs ########################
##################################################################
hostMachine="desktop.vgosai.redhat.com.users.ipa.redhat.com"
hostMachineIP="10.65.144.128"
KubeConfigTempPath=/tmp/kubernetes
##################################################################
############# Kubernetes Certificates Details ####################
##################################################################
C=IN
L=DELHI
O=DevOps
OU=ENG
ST=NEWDELHI
##################################################################
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
