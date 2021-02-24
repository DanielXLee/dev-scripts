#!/usr/bin/env bash

mkdir $GOPATH/src/github.com/kubernetes-app/olm
cd $GOPATH/src/github.com/kubernetes-app/olm
kubebuilder init --domain tkestack.io

echo "Create an API"
kubebuilder create api --group platform --version v1 --kind Olm

