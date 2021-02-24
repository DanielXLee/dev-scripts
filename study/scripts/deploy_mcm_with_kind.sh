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
		  	${script} -i kind
		  2. To cleanup kind cluster:
		  	${script} -r cluster
	EOF
}

install_kind() {
  echo "Installing kind ..."
  curl -Lo ./kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64
  chmod +x ./kind
  mv ./kind /usr/local/bin/kind
}

create_clusters() {
  echo "Creating clusters with kind ..."
  kind create cluster --name $hub_cluster_name
  for NAME in ${managed_cluster_names[@]}
  do
    kind create cluster --name $NAME
  done
}

deploy_mcm() {
  echo "Creating hub cluster"
  kind get kubeconfig --name ${hub_cluster_name} --internal > ~/${hub_cluster_name}-kubeconfig
  kubectl config use-context kind-${hub_cluster_name}
  make deploy-hub
  for NAME in ${managed_cluster_names[@]}
  do
    echo "Creating managed cluster $NAME"
    kind get kubeconfig --name ${NAME} --internal > ~/${NAME}-kubeconfig
    kubectl config use-context kind-${NAME}
    export MANAGED_CLUSTER=${NAME}
    export KLUSTERLET_KIND_KUBECONFIG=~/${NAME}-kubeconfig
    export HUB_KIND_KUBECONFIG=~/${hub_cluster_name}-kubeconfig
    make deploy-spoke-kind
  done
}

cert_approve() {
  kubectl config use-context kind-${hub_cluster_name}
  for NAME in ${managed_cluster_names[@]}
  do
    kubectl certificate approve $(kubectl get csr | grep ${NAME} | awk '{print $1}')
    kubectl patch managedcluster ${NAME} -p='{"spec":{"hubAcceptsClient":true}}' --type=merge
  done
}

deploy_subscription_operator() {
  echo "Deploy the subscription operators to the hub cluster."
  export TRAVIS_BUILD=0
  kubectl config use-context kind-${hub_cluster_name}
  make deploy-community-hub

  echo "Deploy the subscription operators to managed cluster(s)."
  export HUB_KUBECONFIG=~/${hub_cluster_name}-kubeconfig
  for NAME in ${managed_cluster_names[@]}
  do
    export MANAGED_CLUSTER_NAME=${NAME}
    kubectl config use-context kind-${NAME}
    make deploy-community-managed
  done
}

deploy_subscription_cr() {
  kubectl config use-context kind-${hub_cluster_name}
  kubectl apply -f examples/helmrepo-hub-channel

  echo "Checking deployed"
  kubectl config use-context kind-cluster1
  kubectl get subscriptions.apps --watch
}

cleanup_clusters () {
  echo "Cleanup clusters ..."
  kind delete cluster --name $hub_cluster_name
  for NAME in ${managed_cluster_names[@]}
  do
    kind delete cluster --name $NAME
  done
}

clone_code() {
  git clone https://github.com/open-cluster-management/registration-operator.git
  git clone https://github.com/open-cluster-management/multicloud-operators-subscription.git
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

hub_cluster_name="hub"
managed_cluster_names=("cluster1")

if [[ "X$INSTALL" != "X" ]]; then
  if [[ "$INSTALL" == "cluster" ]]; then
    KIND=$(which kind 2>/dev/null)
    if [[ "X$KIND" == "X" ]]; then
      install_kind
    fi
    create_clusters
    clone_code
    (cd registration-operator && deploy_mcm && cert_approve)
    (cd multicloud-operators-subscription && deploy_subscription_operator)
    (cd multicloud-operators-subscription && deploy_subscription_cr)
  fi
fi
if [[ "X$REMOVE" != "X" ]]; then
  if [[ "$REMOVE" == "cluster" ]]; then
    cleanup_clusters
  fi
fi
