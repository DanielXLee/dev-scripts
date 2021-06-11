#!/usr/bin/env bash

msg() {
  printf '%b\n' "$1"
}

success() {
  msg "\33[32m[✔] ${1}\33[0m"
}

warning() {
  msg "\33[33m[✗] ${1}\33[0m"
}

error() {
  msg "\33[31m[✘] ${1}\33[0m"
}

title() {
  msg "\33[34m# ${1}\33[0m"
}

usage () {
  local script="${0##*/}"

  while read -r ; do echo "${REPLY}" ; done <<-EOF
    Usage: ${script} [OPTION]
    Create kind clusters, and deploy open cluster manager
    Options:
    Mandatory arguments to long options are mandatory for short options too.
      -h, --help       Display this help and exit
                       By default deploy mcm cluster
      add              Add managed cluster (create kind cluster, deploy managed components, approve csr...)
      add-app          Deploy application lifecycle manager and sample applicatoin
      add-lable        Add label for managed clusters
      delete           Delete kind cluster
      cleanup          Cleanup all kind clusters
    Examples:
      1. Create kind clusters, and deploy open cluster manager:
        ${script}
      2. Add new managed cluster:
        ${script} add
      3. Add application lifecycle manager components:
        ${script} add-app
EOF
}

install_kind() {
  echo "Installing kind ..."
  curl -Lo ./kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64
  chmod +x ./kind
  mv ./kind /usr/local/bin/kind
}

create_kind_clusters() {
  msg "Creating clusters with kind ..."
  create_kind_cluster $hub_cluster_name
  for NAME in ${managed_cluster_names[@]}
  do
    create_kind_cluster $NAME
  done
}

create_kind_cluster() {
  kind create cluster --name $1
}

deploy_mcm() {
  deploy_hub_cluster
  for NAME in ${managed_cluster_names[@]}
  do
    deploy_managed_cluster $NAME
  done
}

deploy_hub_cluster() {
  msg "Creating hub cluster"
  kind get kubeconfig --name ${hub_cluster_name} --internal > ~/${hub_cluster_name}-kubeconfig
  kubectl config use-context kind-${hub_cluster_name}
  make deploy-hub
}

deploy_managed_cluster() {
  NAME=$1
  msg "Creating managed cluster $NAME"
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
  msg "Approve CSR with command: kubectl certificate approve $(kubectl get csr | grep ${NAME} | awk '{print $1}')"
  kubectl certificate approve $(kubectl get csr | grep ${NAME} | awk '{print $1}')
  msg "Accept cluster with command: kubectl patch managedcluster ${NAME} -p='{\"spec\":{\"hubAcceptsClient\":true}}' --type=merge"
  kubectl patch managedcluster ${NAME} -p='{"spec":{"hubAcceptsClient":true}}' --type=merge
}

deploy_application_operators() {
  msg "Deploy the subscription operators to the hub cluster."
  export TRAVIS_BUILD=0
  kubectl config use-context kind-${hub_cluster_name}
  make deploy-community-hub

  msg "Deploy the subscription operators to managed cluster(s)."
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
  kubectl apply -f deployment.yaml

  msg "Checking deployed resources"
  sleep 60
  msg "Fetch resources on $hub_cluster_name, run command: kubectl -n default get appsub,placementrule,channel,deployable"
  kubectl -n default get appsub,placementrule,channel,deployable
  for NAME in ${managed_cluster_names[@]}
  do
    msg "Fetch resources on $NAME, run command: kubectl --context kind-${NAME} -n default get deploy,po"
    kubectl --context kind-${NAME} -n default get deploy,po
  done
}

add_label_for_managed_clusters() {
  for NAME in ${managed_cluster_names[@]}
  do
    [[ "$NAME" == "cluster1" ]] && continue
    msg "Accept cluster with command: kubectl patch managedcluster ${NAME} -p='{\"metadata\":{\"labels\":{\"environment\": \"Dev\"}}}' --type=merge"
    kubectl patch managedcluster ${NAME} -p='{"metadata":{"labels":{"environment": "Dev"}}}' --type=merge
  done
}

delete_cluster () {
  kind delete cluster --name $1
}

cleanup_all_clusters () {
  msg "Cleanup clusters ..."
  delete_cluster $hub_cluster_name
  for NAME in ${managed_cluster_names[@]}
  do
    delete_cluster $NAME
  done
}

clone_code() {
  git clone https://github.com/kubernetes-app/mcm-example-apps.git
  git clone https://github.com/kubernetes-app/registration-operator.git
  git clone https://github.com/kubernetes-app/multicloud-operators-subscription.git
}

#------------------------------------------- main ---------------------------------------#
hub_cluster_name="hub"
managed_cluster_names=("cluster1" "cluster2" "cluster3")
KIND_VERSION=v0.10.0

if [[ "X$1" == "X" || "$1" == "install" ]]; then
  KIND=$(which kind 2>/dev/null)
  if [[ "X$KIND" == "X" ]]; then
    install_kind
  fi
  title "Step 1: Clone source code and prepare kind clusters"
  clone_code
  create_kind_clusters

  title "Step 2: Deploy hub and managed components on kind clusters"
  pushd registration-operator >/dev/null
  deploy_mcm
  sleep 100
  approve_csrs
  add_label_for_managed_clusters
  popd >/dev/null

  title "Step 3: Deploy application lifecycle components"
  pushd multicloud-operators-subscription >/dev/null
  deploy_application_operators
  popd >/dev/null
  pushd mcm-example-apps >/dev/null
  deploy_application
  popd >/dev/null
elif [[ "$1" == "add" ]]; then
  pushd registration-operator >/dev/null
  title "Step 1: Creating kind cluster $2"
  create_kind_cluster $2
  title "Step 2: Deploy managed components on kind cluster $2"
  deploy_managed_cluster $2
  title "Step 3: Approve CSR for cluster $2"
  approve_csr $2
  popd >/dev/null
elif [[ "$1" == "delete" ]]; then
  pushd registration-operator >/dev/null
  delete_cluster $2
  popd >/dev/null
elif [[ "$1" == "add-app" ]]; then
  pushd multicloud-operators-subscription >/dev/null
  title "Step 1: Deploy application lifecycle components"
  deploy_application_operators
  title "Step 2: Deploy application"
  deploy_application
  popd >/dev/null
elif [[ "$1" == "add-label" ]]; then
  add_label_for_managed_clusters
elif [[ "$1" == "cleanup" ]]; then
  cleanup_all_clusters
elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
  usage
fi
