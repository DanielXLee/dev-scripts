#!/usr/bin/env bash

echo "Step #1: Init project"
mkdir memcached-operator
cd memcached-operator
operator-sdk init --domain example.com --repo github.com/kubernetes-app/memcached-operator

echo "Step #2: Create API"
operator-sdk create api --group cache --version v1alpha1 --kind Memcached --resource --controller

echo "Step #3: Build and push operator image to docker hub"
export OPERATOR_IMG="blackholex/memcached-operator:v0.0.1"
make docker-build docker-push IMG=$OPERATOR_IMG
