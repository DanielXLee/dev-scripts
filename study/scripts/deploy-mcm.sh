#!/usr/bin/env bash
KIND_VERSION=v0.10.0

usage () {
	local script="${0##*/}"

	while read -r ; do echo "${REPLY}" ; done <<-EOF
		Usage: ${script} [OPTION]
		Install packages, and create kind clusters
		Options:
		Mandatory arguments to long options are mandatory for short options too.
			-h, --help       Display this help and exit
			deploy           Deploy open cluster manager and subscription
			remove           Remove resource
		Examples:
		  1. Deploy open cluster manager and subscription operator:
		  	${script} deploy
		  2. To cleanup kind cluster:
		  	${script} remove
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
  create_cluster $hub_cluster_name
  for NAME in ${managed_cluster_names[@]}
  do
    create_cluster $NAME
  done
}

create_cluster() {
  NAME=$1
  echo "Creating cluster $NAME ..."
  kind create cluster --name $NAME
}

deploy_mcm() {
  echo "Creating hub cluster"
  kind get kubeconfig --name ${hub_cluster_name} --internal > ~/${hub_cluster_name}-kubeconfig
  kubectl config use-context kind-${hub_cluster_name}
  make deploy-hub
  for NAME in ${managed_cluster_names[@]}
  do
    create_managed_cluster $NAME
  done
}

create_managed_cluster() {
  NAME=$1
  echo "Creating managed cluster $NAME"
  kind get kubeconfig --name ${NAME} --internal > ~/${NAME}-kubeconfig
  kubectl config use-context kind-${NAME}
  export MANAGED_CLUSTER=${NAME}
  export KLUSTERLET_KIND_KUBECONFIG=~/${NAME}-kubeconfig
  export HUB_KIND_KUBECONFIG=~/${hub_cluster_name}-kubeconfig
  make deploy-spoke-kind
}

approve_csrs() {
  for NAME in ${managed_cluster_names[@]}
  do
    approve_csr $NAME
  done
}

approve_csr() {
  NAME=$1
  kubectl config use-context kind-${hub_cluster_name}
  echo "Approve CSR with command: kubectl certificate approve $(kubectl get csr | grep ${NAME} | awk '{print $1}')"
  kubectl certificate approve $(kubectl get csr | grep ${NAME} | awk '{print $1}')
  echo "Accept cluster with command: kubectl patch managedcluster ${NAME} -p='{"spec":{"hubAcceptsClient":true}}' --type=merge"
  kubectl patch managedcluster ${NAME} -p='{"spec":{"hubAcceptsClient":true}}' --type=merge
}

deploy_application_operators() {
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

deploy_application() {
  kubectl config use-context kind-${hub_cluster_name}
  kubectl apply -f examples/helmrepo-hub-channel

  echo "Checking deployed resources"
  sleep 60
  echo "Fetch resources on $hub_cluster_name, run command: kubectl -n default get appsub,placementrule,channel,deployable"
  kubectl -n default get appsub,placementrule,channel,deployable
  for NAME in ${managed_cluster_names[@]}
  do
    echo "Fetch resources on $NAME, run command: kubectl --context kind-${NAME} -n default get deploy,po"
    kubectl --context kind-${NAME} -n default get deploy,po
  done
}

delete_cluster () {
  NAME=$1
  echo "Delete cluster $NAME..."
  kind delete cluster --name $NAME
}

cleanup_all_clusters () {
  echo "Cleanup clusters ..."
  kind delete cluster --name $hub_cluster_name
  for NAME in ${managed_cluster_names[@]}
  do
    kind delete cluster --name $NAME
  done
}

clone_code() {
  git clone https://github.com/kubernetes-app/registration-operator.git
  git clone https://github.com/open-cluster-management/multicloud-operators-subscription.git
}

#------------------------------------------- main ---------------------------------------#
hub_cluster_name="hub"
managed_cluster_names=("cluster1" "cluster2" "cluster3")

if [[ "X$1" == "X" || "$1" == "install" ]]; then
  KIND=$(which kind 2>/dev/null)
  if [[ "X$KIND" == "X" ]]; then
    install_kind
  fi
  create_clusters
  clone_code
  (cd registration-operator && deploy_mcm && approve_csrs)
  (cd multicloud-operators-subscription && deploy_application_operators)
  (cd multicloud-operators-subscription && deploy_application)
elif [[ "$1" == "add" ]]; then
  pushd registration-operator
  create_cluster $2
  create_managed_cluster $2
  approve_csr $2
  popd
elif [[ "$1" == "delete" ]]; then
  pushd registration-operator
  delete_cluster $2
  popd
elif [[ "$1" == "app" ]]; then
  pushd multicloud-operators-subscription
  deploy_application_operators
  deploy_application
  popd
elif [[ "$1" == "cleanup" ]]; then
  cleanup_all_clusters
fi
