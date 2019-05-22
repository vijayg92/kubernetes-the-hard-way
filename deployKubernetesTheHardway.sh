#!/bin/bash

### Checking Prerequisites prior to deploying Kubernetes ###
if [ -f ./checkPrerequisites.sh ]; then
    echo ""
    echo "Checking initial Prerequisites before deploying the cluser"
    source ./checkPrerequisites.sh
    main
    echo ""
fi

### Installation of all the required binaries related to Kubernetes ###
if [ -f ./installBinaries.sh ]; then
    echo "Installating required binaries on the host machine."
    source ./installBinaries.sh
    main
    echo ""
fi

### Provisioning CA and TLS Certificates ###
if [ -f ./provisionCerts.sh ]; then
    echo "Provisioning required certificates on the host machine."
    source ./provisionCerts.sh
    main
    echo ""
fi

### Generating & Distrubuting of Kubernetes Config files ###
if [ -f ./generateKubeConfigs.sh ]; then
    echo "Generating & Distributing Kubernetes Configs files on Kubernetes Master, LB Server and nodes"
    source ./generateKubeConfigs.sh
	main
	echo ""
fi

### Bootstrapping ETCD cluster ###
if [ -f ./bootstrapEtcd.sh ]; then
    echo "Bootstrapping ETCD Cluster"
    source ./bootstrapEtcd.sh
	main
	echo ""
fi

### Bootstrapping Kubernetes Control Plane ###

### Bootstrapping Kubernetes Worker nodes ###

### Configuring kubectl for remote access ###

### Deploying DNS and cluster Add Ons ###

### Somke Test ###
