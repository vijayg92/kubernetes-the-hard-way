#!/bin/bash

### Checking Prerequisites ###
if [ -f ./initialCheck.sh ]; then
    echo -e "Checking initial Prerequisites before deploying the cluser\n"
    source ./initialCheck.sh
    _checkPrerequisites
fi

### Installation of Tools ###
if [ -f ./installBinaries.sh ]; then
    echo -e "Installating required binaries on the host machine..\n"
    source ./installBinaries.sh
    _installBinaries
fi

### Provisioning Certificates ###
if [ -f ./provisionCerts.sh ]; then
    echo -e "Provisioning required certificates on the host machine..\n"
    source ./provisionCerts.sh
    _provisionCerts
fi
