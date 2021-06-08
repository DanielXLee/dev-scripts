#!/usr/bin/env bash

git clone https://github.com/karmada-io/karmada.git

KUBECONFIG="$HOME/.kube/config"

echo "Creating local up karmada cluster"
./karmada/hack/local-up-karmada.sh
cp $HOME/.kube/karmada.config $KUBECONFIG

echo "Creating member cluster"
./karmada/hack/create-cluster.sh member1 $KUBECONFIG
./karmada/hack/create-cluster.sh member2 $KUBECONFIG

echo "Switch to karmada-apiserver context"
kubectl config use-context karmada-apiserver

KARMADACTL=$(which karmadactl 2>/dev/null)
if [[ "X$KARMADACTL" == "X" ]]; then
  echo "Installing karmadactl cmd"
go get github.com/karmada-io/karmada/cmd/karmadactl
fi

echo "Join member cluster to karmada"
karmadactl join member1 --cluster-kubeconfig=$KUBECONFIG
karmadactl join member2 --cluster-kubeconfig=$KUBECONFIG

echo "Deploy a sample"
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
      - image: nginx
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

echo "Check po on memeber1 cluster"
kubectl --context member1 get deploy,po -n default
kubectl --context member2 get deploy,po -n default

echo 
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

echo "Check pods with schedule policy"
kubectl --context member1 get deploy,po -n default
kubectl --context member2 get deploy,po -n default
