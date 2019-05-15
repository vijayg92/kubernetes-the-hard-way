#!/bin/bash

### Checking Prerequisites prior to deploying Kubernetes ###
if [ -f ./checkPrerequisites.sh ]; then
    echo -e "Checking initial Prerequisites before deploying the cluser\n"
    source ./checkPrerequisites.sh
    main
fi

### Installation of all the required binaries related to Kubernetes ###
if [ -f ./installBinaries.sh ]; then
    echo -e "Installating required binaries on the host machine..\n"
    source ./installBinaries.sh
    main
fi

### Provisioning CA and TLS Certificates ###
if [ -f ./provisionCerts.sh ]; then
    echo -e "Provisioning required certificates on the host machine..\n"
    source ./provisionCerts.sh
    main
fi

### Generating & Distrubuting of Kubernetes Config files ###
if [ -f ./generateKubeConfigs.sh ]; then
    echo "Generating & Distributing Kubernetes Configs files on Kubernetes Worker and Master nodes\n"
    source ./generateKubeConfigs.sh
	main
fi

### Bootstrapping ETCD cluster ###
if [ -f ./bootstrapEtcd.sh ]; then
    echo "Bootstrapping ETCD Cluster"
    source ./bootstrapEtcd.sh
	main
fi

### Bootstrapping Kubernetes Control Plane ###

### Bootstrapping Kubernetes Worker nodes ###

### Configuring kubectl for remote access ###

### Deploying DNS and cluster Add Ons ###

### Somke Test ###
