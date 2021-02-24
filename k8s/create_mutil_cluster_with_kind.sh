#!/usr/bin/env bash
KIND_VERSION=v0.10.0

usage () {
	local script="${0##*/}"

	while read -r ; do echo "${REPLY}" ; done <<-EOF
		Usage: ${script} [OPTION]
		Install packages, and create kind clusters
		Options:
		Mandatory arguments to long options are mandatory for short options too.
			-h, --help          Display this help and exit
			-i install          Install packages, supported types [helm, kind, argocd, metallb, cluster]
			-r remove           Remove resource
		Examples:
		  1. Install package:
		  	${script} -i helm
		  2. To cleanup kind cluster:
		  	${script} -r cluster
	EOF
}

install_helm() {
  echo "Installing helm v3 ..."
  curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
}

install_kind() {
  echo "Installing kind ..."
  curl -Lo ./kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64
  chmod +x ./kind
  mv ./kind /usr/local/bin/kind
}

create_clusters() {
  echo "Creating clusters with kind ..."
  for CLUSTER_NAME in ${cluster_names[@]}
  do
    kind create cluster --name $CLUSTER_NAME --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
EOF
  done
}

cleanup_clusters () {
  echo "Cleanup clusters ..."
  for CLUSTER_NAME in ${cluster_names[@]}
  do
    kind delete cluster --name $CLUSTER_NAME
  done
}

install_argo_cd() {
  echo "Installing Argo CD ..."
  for CLUSTER_NAME in ${cluster_names[@]}
  do
    kubectl --context kind-$CLUSTER_NAME create namespace argocd
    kubectl --context kind-$CLUSTER_NAME apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
  done
}

# How to get service of type LoadBalancer working in a kind cluster using Metallb.
install_metallb() {
  echo "Installing MetalLb ..."
  for CLUSTER_NAME in ${cluster_names[@]}
  do
    kubectl --context kind-cd apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/namespace.yaml
    kubectl --context kind-cd create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)" 
    kubectl --context kind-cd apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/metallb.yaml
    kubectl --context kind-cd apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 172.18.255.200-172.18.255.250
EOF
  done
}

#------------------------------------------- main ---------------------------------------#
INSTALL=
REMOVE=

while [ "$#" -gt "0" ]
do
	case "$1" in
	"-h"|"--help")
		usage
		exit 0
		;;
	"-i")
		shift
		INSTALL="$1"
		;;
	"-r")
		shift
		REMOVE="$1"
		;;
	*)
		echo "invalid option -- \`$1'"
    exit 1
		;;
	esac
	shift
done

cluster_names=("hub" "cluster1")
echo "Setup separate kubeconfig for this exercise"
export KUBECONFIG=~/kubeconfig-admiralty-getting-started

if [[ "X$INSTALL" != "X" ]]; then
  if [[ "$INSTALL" == "helm" ]]; then
    install_helm
  elif [[ "$INSTALL" == "kind" ]]; then
    install_kind
  elif [[ "$INSTALL" == "argocd" ]]; then
    install_argo_cd
  elif [[ "$INSTALL" == "metallb" ]]; then
    install_metallb
  elif [[ "$INSTALL" == "cluster" ]]; then
    create_clusters
  fi
fi
if [[ "X$REMOVE" != "X" ]]; then
  if [[ "$REMOVE" == "cluster" ]]; then
    cleanup_clusters
  fi
fi
