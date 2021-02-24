#!/bin/bash

function create_sc() {
if [[ $(uname -m) == x86_64 ]]; then
if [[ `oc get sc --all-namespaces --no-headers --ignore-not-found | wc -l` -eq 0 ]]; then
  yum install git -y
  yum install make -y
  git clone --single-branch --branch release-1.3 https://github.com/rook/rook.git
  oc create -f rook/cluster/examples/kubernetes/ceph/common.yaml
  oc create -f rook/cluster/examples/kubernetes/ceph/operator-openshift.yaml
  cat <<EOF | tee -a rook/cluster/examples/kubernetes/ceph/cluster.yaml
    nodes:
    - name: "`oc get nodes | grep worker | awk '{print $1}' | awk 'NR==1{print}'`"
      devices: # specific devices to use for storage can be specified for each node
      - name: "vdb"
    - name: "`oc get nodes | grep worker | awk '{print $1}' | awk 'NR==2{print}'`"
      devices: # specific devices to use for storage can be specified for each node
      - name: "vdb"
    - name: "`oc get nodes | grep worker | awk '{print $1}' | awk 'NR==2{print}'`"
      devices: # specific devices to use for storage can be specified for each node
      - name: "vdb"
EOF
 oc create -f rook/cluster/examples/kubernetes/ceph/cluster.yaml
 oc create -f rook/cluster/examples/kubernetes/ceph/csi/rbd/storageclass.yaml
else
  echo "Already existed the stroageclass."
fi
fi
}
create_sc
