#!/bin/bash

echo "Deploying TDCC environment..."

echo "Creating meta cluster"
kind create cluster --name meta

echo "Creating child-1 cluster"
kind create cluster --name child-1

meta_cluster_container_id=$(docker ps -a | grep meta | awk '{print $1}')

echo "Pre-load images to kind cluster"
platform_api_image=csighub.tencentyun.com/danielxxli/tke-platform-api-amd64:v0.0.1
platform_controller_image=csighub.tencentyun.com/danielxxli/tke-platform-controller-amd64:v0.0.1
application_api_image=csighub.tencentyun.com/danielxxli/tke-application-api-amd64:v0.0.1
application_controller_image=csighub.tencentyun.com/danielxxli/tke-application-controller-amd64:v0.0.1

kind load docker-image ${platform_api_image}  --name meta
kind load docker-image ${platform_controller_image}  --name meta
kind load docker-image ${application_api_image}  --name meta
kind load docker-image ${application_controller_image} --name meta

echo "Waiting for kind node ready..."
sleep 30

etcd_host=$(docker exec -it $meta_cluster_container_id hostname -I | awk '{print $4}')
echo "etcd_host: $etcd_host"
etcdcacrt=$(docker exec -it $meta_cluster_container_id cat /etc/kubernetes/pki/etcd/ca.crt | base64 -w 0)
etcdcrt=$(docker exec -it $meta_cluster_container_id cat /etc/kubernetes/pki/apiserver-etcd-client.crt | base64 -w 0)
etcdkey=$(docker exec -it $meta_cluster_container_id cat /etc/kubernetes/pki/apiserver-etcd-client.key | base64 -w 0)

chart_path=/root/tdcc/platform-charts/tdcc
echo "Update etcd ca certs"
sed -i "s|host:.*2379.*|host: https://${etcd_host}:2379|" ${chart_path}/platform-api/values.yaml
sed -i "s|etcdcacrt:.*|etcdcacrt: ${etcdcacrt}|" ${chart_path}/platform-api/values.yaml
sed -i "s|etcdcrt:.*|etcdcrt: ${etcdcrt}|" ${chart_path}/platform-api/values.yaml
sed -i "s|etcdkey:.*|etcdkey: ${etcdkey}|" ${chart_path}/platform-api/values.yaml


sed -i "s|host:.*2379.*|host: https://${etcd_host}:2379|" ${chart_path}/application-api/values.yaml
sed -i "s|etcdcacrt:.*|etcdcacrt: ${etcdcacrt}|" ${chart_path}/application-api/values.yaml
sed -i "s|etcdcrt:.*|etcdcrt: ${etcdcrt}|" ${chart_path}/application-api/values.yaml
sed -i "s|etcdkey:.*|etcdkey: ${etcdkey}|" ${chart_path}/application-api/values.yaml

echo "Update images"
sed -i "s|image:.*|image: ${platform_api_image}|" ${chart_path}/platform-api/values.yaml
sed -i "s|image:.*|image: ${platform_controller_image}|" ${chart_path}/platform-controller/values.yaml
sed -i "s|image:.*|image: ${application_api_image}|" ${chart_path}/application-api/values.yaml
sed -i "s|image:.*|image: ${application_controller_image}|" ${chart_path}/application-controller/values.yaml
sed -i "s|imagePullPolicy:.*|imagePullPolicy: IfNotPresent|" ${chart_path}/platform-api/values.yaml
sed -i "s|imagePullPolicy:.*|imagePullPolicy: IfNotPresent|" ${chart_path}/platform-controller/values.yaml
sed -i "s|imagePullPolicy:.*|imagePullPolicy: IfNotPresent|" ${chart_path}/application-api/values.yaml
sed -i "s|imagePullPolicy:.*|imagePullPolicy: IfNotPresent|" ${chart_path}/application-controller/values.yaml


echo "Install helm charts"
kubectl config use-context kind-meta
helm install tdcc-platform-api ${chart_path}/platform-api/ -n kube-system  
helm install tdcc-platform-controller ${chart_path}/platform-controller/ -n kube-system 
helm install tdcc-application-api ${chart_path}/application-api/ -n kube-system 
helm install tdcc-application-controller ${chart_path}/application-controller/ -n kube-system

echo "Waiting for platform-api and application-api ready..."
platform_api_pod=$(kubectl -n kube-system get po -l app=tke-platform-api --no-headers | awk '{print $1}')
kubectl wait --for=condition=Ready pod/$platform_api_pod
app_api_pod=$(kubectl -n kube-system get po -l app=tke-application-api --no-headers | awk '{print $1}')
kubectl wait --for=condition=Ready pod/$app_api_pod
# sleep 60

echo "Update platform and application conf"
platfrom_server=$(kubectl -n kube-system get po -o wide | grep platform-api | awk '{print $6}')
app_server=$(kubectl -n kube-system get po -o wide | grep application-api | awk '{print $6}')

sed -i "s|server:.*|server: https://${platfrom_server}:9443|" platform.conf
sed -i "s|server:.*|server: https://${app_server}:9463|" application.conf

docker cp platform.conf ${meta_cluster_container_id}:/root
docker cp application.conf ${meta_cluster_container_id}:/root

echo "Import a cluster"
kubectl config use-context kind-child-1
cat <<EOF | kubectl apply -f -
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: admin
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: admin
  namespace: kube-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin
  namespace: kube-system
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
EOF

child_1_token=$(kubectl -n kube-system get secret $(kubectl -n kube-system get serviceaccount admin -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 -d)
sed -i "s|token:.*|token: ${child_1_token}|" imp-cc.yaml
sed -i "s|host:.*|host: child-1-control-plane|" imp-cluster.yaml
sed -i 's|"host":.*|"host": "child-1-control-plane"|' hub-cluster.yaml

echo "Create cluster import obj"
docker cp imp-cc.yaml ${meta_cluster_container_id}:/root
docker cp imp-cluster.yaml ${meta_cluster_container_id}:/root
docker cp hub-cluster.yaml ${meta_cluster_container_id}:/root
# docker exec -it $meta_cluster_container_id kubectl create -f /root/imp-cc.yaml --kubeconfig /root/platform.conf
# docker exec -it $meta_cluster_container_id kubectl create -f /root/imp-cluster.yaml --kubeconfig /root/platform.conf
docker exec -it $meta_cluster_container_id kubectl create -f /root/hub-cluster.yaml --kubeconfig /root/platform.conf
echo "Verify imported cluster"
docker exec -it $meta_cluster_container_id kubectl get cluster --kubeconfig /root/platform.conf

