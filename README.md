# Kubernetes the hard way

*A simple and real quick installation of Kubernetes the hard way*


## Prerequisites

1. You must have root access on all the nodes `(Master, Workers and Local Host).`
2. A keyless authentication must be set among `Kubernetes Nodes & Local Host.`
3. Kubernetes Controllers details must be updated in `clusterConfigs.txt.`
4. Kubernetes Workers details must be updated in `clusterConfigs.txt.`
5. Kubernetes Certificates details must be updated in `clusterConfigs.txt.`
6. Before installation of the cluster, make sure to run `initialChecks.sh.` script to validate all configs.

## Usage
1. `clusterConfigs.txt`: *Stores Kubernetes Cluster Configurations*
2. `initialCheck.sh`:  *Script to run initial checks*
3. `installBinaries.sh`: *Installs all the required binaries.*
4. `provisionCerts.sh` : *Provisions of all the required certificates.*
5. `generateKubeConfigs.sh`: *Generates all the required Kubernetes Configuration files.*
6. `bootstrapControlpanes.sh`: *Bootstraps Kubernetes Control panes (masters).*
7. `bootstrapEtcd.sh`: *Bootstraps ETCD cluster.*
8. `bootstrapWorkerNodes.sh`: *Bootstraps Kubernetes nodes.*
9. `validateCluster.sh`: *Validate deployment of the cluster.*
10. `deploy_kubernetes_the_hardway.sh`: *This is the main script which sequentially performs all the above steps to deploy the cluster in a hard way.*
## Installation

1. Clone the repository -

```bash
git clone https://github.com/vijayg92/kubernetes-the-hard-way.git
cd kubernetes-the-hard-way
```
2. Run `initialCheck.sh` script to validate prerequisites.
```bash
./initialCheck.sh
```
3. If step 2 works fine then deploy the cluster by running `deploy_kubernetes_the_hard_way.sh` script
```bash
./deploy_kubernetes_the_hard_way.sh
```
4. Finally validation the cluster.

```bash
./validateCluster.sh
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
[GPLv3](https://www.gnu.org/licenses/)
