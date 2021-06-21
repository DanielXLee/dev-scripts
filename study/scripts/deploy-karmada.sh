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

pre_deploy(){
  cleanup
  git clone https://github.com/karmada-io/karmada.git
}

cleanup() {
  title "Cleanup karmada environment"
  kind delete cluster --name karmada-host
  for NAME in ${member_clusters[@]}
  do
    kind delete cluster --name $NAME
  done
  rm -rf karmada $KUBECONFIG $KARMADA_KUBECONFIG
}

deploy() {
  title "Creating local up karmada cluster"
  ./karmada/hack/local-up-karmada.sh
  cp $KARMADA_KUBECONFIG $KUBECONFIG
}

create_and_join_member() {
  title "Creating member cluster"
  for NAME in ${member_clusters[@]}
  do
    ./karmada/hack/create-cluster.sh $NAME $KUBECONFIG
  done

  title "Switch to karmada-apiserver context"
  kubectl config use-context karmada-apiserver

  KARMADACTL=$(which karmadactl 2>/dev/null)
  if [[ "X$KARMADACTL" == "X" ]]; then
    title "Installing karmadactl cmd"
    go get github.com/karmada-io/karmada/cmd/karmadactl
  fi

  title "Join member cluster to karmada"
  for NAME in ${member_clusters[@]}
  do
    karmadactl join $NAME --cluster-kubeconfig=$KUBECONFIG
  done
}

deploy_sample() {
  title "Deploy a sample"
  kubectl apply -f - <<EOF
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: nginx
    labels:
      app: nginx
  spec:
    replicas: 1
    selector:
      matchLabels:
        app: nginx
    template:
      metadata:
        labels:
          app: nginx
      spec:
        containers:
        - image: docker.io/nginx
          name: nginx
EOF

  kubectl apply -f - <<EOF
  apiVersion: policy.karmada.io/v1alpha1
  kind: PropagationPolicy
  metadata:
    name: nginx-propagation
  spec:
    resourceSelectors:
      - apiVersion: apps/v1
        kind: Deployment
        name: nginx
    placement:
      clusterAffinity:
        clusterNames:
          - member1
          - member2
EOF

  for NAME in ${member_clusters[@]}
  do
    title "Check deploy/po status on $NAME cluster with cmd: kubectl --context $NAME get deploy,po -n default"
    kubectl --context $NAME get deploy,po -n default
  done

  title "Deploy ReplicaSchedulingPolicy"
  kubectl apply -f - <<EOF
  apiVersion: policy.karmada.io/v1alpha1
  kind: ReplicaSchedulingPolicy
  metadata:
    name: nginx-replica
  spec:
    resourceSelectors:
      - apiVersion: apps/v1
        kind: Deployment
        namespace: default
        name: nginx
    totalReplicas: 10
    preferences:
      staticWeightList:
        - targetCluster:
            clusterNames: [member1]
          weight: 1
        - targetCluster:
            clusterNames: [member2]
          weight: 2
EOF

  for NAME in ${member_clusters[@]}
  do
    title "Check deploy/po status on $NAME cluster with cmd: kubectl --context $NAME get deploy,po -n default"
    kubectl --context $NAME get deploy,po -n default
  done
}

#--------------------------------------------- Main ---------------------------------------------#
member_clusters=("member1" "member2")
KUBECONFIG="$HOME/.kube/config"
KARMADA_KUBECONFIG=$HOME/.kube/karmada.config

if [[ "X$1" == "X" || "$1" == "deploy" ]]; then
  pre_deploy
  deploy
  create_and_join_member
  deploy_sample
elif [[ "$1" == "cleanup" ]]; then
  cleanup
fi
