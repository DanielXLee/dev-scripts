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
    Create kind clusters, and deploy clusternet registry cluster
    Options:
    Mandatory arguments to long options are mandatory for short options too.
      -h, --help       Display this help and exit
                       By default deploy clusternet cluster
      delete           Delete kind cluster
      cleanup          Cleanup all kind clusters
    Examples:
      1. Create kind clusters, and deploy clusternet cluster:
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

create_kind_cluster() {
  kind create cluster --name $1
}

create_kind_clusters() {
  msg "Creating clusters with kind ..."
  create_kind_cluster $hub_cluster_name
  for NAME in ${managed_cluster_names[@]}
  do
    create_kind_cluster $NAME
  done
}

deploy_clusternet() {
  deploy_clusternet_hub
  HUB_APISERVER="https://${hub_cluster_name}-control-plane:6443"
  for NAME in ${managed_cluster_names[@]}
  do
    deploy_clusternet_agent $NAME
  done
}

deploy_clusternet_hub() {
  title "Creating clusternet hub"
  kubectl config use-context kind-${hub_cluster_name}
  kubectl apply -f deploy/hub
  kubectl apply -f manifests/samples
}

deploy_clusternet_agent() {
  NAME=$1
  title "Creating clusternet agent for managed cluster $NAME"
  kubectl config use-context kind-${NAME}
  # create namespace clusternet-system and edge-system if not created
  kubectl create ns clusternet-system
  kubectl create ns edge-system
  # here we use the token created above
  PARENTURL=$HUB_APISERVER REGTOKEN=07401b.f395accd246ae52d envsubst < ./deploy/templates/clusternet_agent_secret.yaml | kubectl apply -f -
  kubectl apply -f deploy/agent
}

deploy_application_lifecycle_manager() {
  msg "Deploy the subscription and application manager operators to the hub cluster."
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

delete_cluster () {
  kind delete cluster --name $1
}

cleanup_all_clusters () {
  title "Cleanup clusters ..."
  delete_cluster $hub_cluster_name
  for NAME in ${managed_cluster_names[@]}
  do
    delete_cluster $NAME
  done
}

clone_code() {
  git clone -b develop https://github.com/DanielXLee/clusternet.git
  git clone -b clusternet https://github.com/kubernetes-app/multicloud-operators-subscription.git
}

#------------------------------------------- main ---------------------------------------#
hub_cluster_name="hub"
managed_cluster_names=("cluster1" "cluster2")
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
  pushd clusternet >/dev/null
  deploy_clusternet
  popd >/dev/null

  title "Step 3: Deploy application lifecycle components"
  pushd multicloud-operators-subscription >/dev/null
  deploy_application_lifecycle_manager
  popd >/dev/null

  # title "Step 4: Deploy a sample application"
  # pushd mcm-example-apps >/dev/null
  # sample_application
  # popd >/dev/null
elif [[ "$1" == "lifecycle" ]]; then
  title "Deploy application lifecycle components"
  pushd multicloud-operators-subscription >/dev/null
  deploy_application_lifecycle_manager
  popd >/dev/null
elif [[ "$1" == "delete" ]]; then
  delete_cluster $2
elif [[ "$1" == "cleanup" ]]; then
  cleanup_all_clusters
elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
  usage
fi
