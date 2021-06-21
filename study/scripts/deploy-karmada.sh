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

KUBECONFIG="$HOME/.kube/config"
KARMADA_KUBECONFIG=$HOME/.kube/karmada.config
rm -rf karmada $KUBECONFIG $KARMADA_KUBECONFIG
kind delete cluster --name karmada-host
kind delete cluster --name member1
kind delete cluster --name member2
git clone https://github.com/karmada-io/karmada.git

title "Creating local up karmada cluster"
./karmada/hack/local-up-karmada.sh
cp $KARMADA_KUBECONFIG $KUBECONFIG

title "Creating member cluster"
./karmada/hack/create-cluster.sh member1 $KUBECONFIG
./karmada/hack/create-cluster.sh member2 $KUBECONFIG

title "Switch to karmada-apiserver context"
kubectl config use-context karmada-apiserver

KARMADACTL=$(which karmadactl 2>/dev/null)
if [[ "X$KARMADACTL" == "X" ]]; then
  title "Installing karmadactl cmd"
  go get github.com/karmada-io/karmada/cmd/karmadactl
fi

title "Join member cluster to karmada"
karmadactl join member1 --cluster-kubeconfig=$KUBECONFIG
karmadactl join member2 --cluster-kubeconfig=$KUBECONFIG

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

title "Check po on memeber1 cluster"
kubectl --context member1 get deploy,po -n default
kubectl --context member2 get deploy,po -n default

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

title "Check pods with schedule policy"
kubectl --context member1 get deploy,po -n default
kubectl --context member2 get deploy,po -n default
