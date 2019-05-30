#!/bin/bash
set -e

#### Checking Prerequisites prior to deploying Kubernetes ###
if [ ! -f ./checkPrerequisites.sh ]; then
		echo "Error : Unable to get ./checkPrerequisites.sh!!"
		exit 1
else
		echo ""
		echo "Checking initial Prerequisites before deploying the cluser"
		source ./checkPrerequisites.sh
		main
fi

#### Installation of all the required binaries related to Kubernetes ###
if [ ! -f ./installBinaries.sh ]; then
		echo "Error : Unable to get ./installBinaries.sh!!"
		exit 1
else
		echo ""
	  echo "Installing required binaries on the host machine."
	  source ./installBinaries.sh
	  main
fi

#### Provisioning CA and TLS Certificates ###
if [ ! -f ./provisionKubeCerts.sh ]; then
		echo "Error : Unable to get ./provisionKubeCerts.sh!!"
		exit 1
else
		echo ""
		echo "Provisioning required certificates on the host machine."
    source ./provisionKubeCerts.sh
    main
fi

#### Generating & Distrubuting of Kubernetes Config files ###
if [ ! -f ./provisionKubeConfigs.sh ]; then
		echo "Error : Unable to get ./provisionKubeConfigs.sh!!"
		exit 1
else
		echo ""
		echo "Provisioning Kubernetes Configs files on Kubernetes Master, LB Server and nodes"
    source ./provisionKubeConfigs.sh
		main
fi

### Bootstrapping Kubernetes ETCD Cluster, Controller Nodes and Worker Nodes ###
if [ ! -f ./provisionKubernetesCluster.sh ]; then
		echo "Error : Unable to get ./provisionKubeConfigs.sh!!"
		exit 1
else
		echo ""
		echo "Bootstrapping Kubernetes ETCD Cluster, Controller Nodes and Worker Nodes"
    source ./provisionKubernetesCluster.sh
		main
fi

### Configuring kubectl for Remote Access ###

### Configuring Kubernetes CNI Networking ###

### Configuring Kubernetes DNS - KubeDNS ###

### Validating Cluster Deployment - Somke Test ###
