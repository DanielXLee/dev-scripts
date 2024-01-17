#!/bin/bash

set_deployment_image() {
  DEPLOYMENT=$1
  CONTAINER_NAME=$DEPLOYMENT
  NEW_IMAGE=csighub.tencentyun.com/danielxxli/${DEPLOYMENT}:${TAG}
  kubectl set image deployment/${DEPLOYMENT}-${ENV_ID} ${CONTAINER_NAME}=${NEW_IMAGE}
}

set_statefulset_image(){
  STATEFULSET=$1
  CONTAINER_NAME=$2
  NEW_IMAGE=csighub.tencentyun.com/danielxxli/${STATEFULSET}:${TAG}
  kubectl set image statefulset/${STATEFULSET}-${ENV_ID} ${CONTAINER_NAME}=${NEW_IMAGE}
}

PROJECT=${PROJECT:-"tke"}
DEPLOYMENT_NAME=${DEPLOYMENT_NAME:-""}
IMAGE=${IMAGE:-""}
TARGET_REPO=danielxxli
VERSION=$(git describe --tags --always --match='v*')

# opts parse
while getopts "p:e:i:t:" opt; do
  case $opt in
    p)
      PROJECT=$OPTARG
      ;;
    e)
      ENV_ID=$OPTARG
      ;;
    i)
      IMAGE=$OPTARG
      DEPLOYMENT_NAME=$OPTARG
      ;;
    t)
      TAG=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

# Update new image to test env
# kubecm s caas-test
if [ "$PROJECT" == "tke" ]; then
  if [ -z "$DEPLOYMENT_NAME" ]; then
    set_deployment_image tke-machineset-controller
    set_deployment_image tke-native-cvm-controller
    set_deployment_image tke-cxm-controller
    set_deployment_image tke-node-apiserver
    set_deployment_image tke-node-controller-manager
  else
    set_deployment_image $DEPLOYMENT_NAME
  fi
elif [ "$PROJECT" == "gw" ]; then
  set_deployment_image tke-node-cloud-gw
elif [ "$PROJECT" == "eks" ]; then
  set_statefulset_image eks-server eks-server
  set_statefulset_image eks-server async-server
elif [ "$PROJECT" == "dashboard" ]; then
  set_deployment_image dashboard
else
  echo "invalid project: $PROJECT"
  exit 1
fi


