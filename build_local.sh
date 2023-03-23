#!/bin/bash

IMAGE="087473112489.dkr.ecr.us-west-1.amazonaws.com/4sweep:latest"

if [ -f ~/.artifactory_creds ]; then
    ARTIFACTORY_CREDS=$(tr '\n' ' ' <<<$CREDS_FILE | sed "s/artifactory_username=\(.*\) artifactory_password=\(.*\)/\1:\2/")
    docker build -t $IMAGE --build-arg artifactory_creds="${ARTIFACTORY_CREDS}" .
else
    docker build -t $IMAGE .
fi

