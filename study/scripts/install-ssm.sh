#!/bin/bash

kubectl create ns sso

helm upgrade --install service-spec oci://ccr.ccs.tencentyun.com/tcs-charts/ssm-spec \
--version 2.3.0 -n ssm --create-namespace

helm upgrade --install stateset-controller oci://ccr.ccs.tencentyun.com/tcs-charts/stateset-controller \
--version 2.3.0 -n ssm --create-namespace \
--set deploy.platform=PublicCloud \
--set registry=ccr.ccs.tencentyun.com/tcs-infra

helm upgrade --install provisioner oci://ccr.ccs.tencentyun.com/tcs-charts/provisioner \
--version 2.3.0 -n ssm --create-namespace \
--set deploy.platform=PublicCloud \
--set kubeletRoot=/var/lib/kubelet \
--set affinity= \
--set registry=ccr.ccs.tencentyun.com/tcs-infra

helm upgrade --install csi-driver-localpv oci://ccr.ccs.tencentyun.com/tcs-charts/csi-driver-localpv \
--version 2.3.0 -n ssm --create-namespace \
--set allowNoQuota=true \
--set directLoop=false \
--set deploy.platform=PublicCloud \
--set kubeletRoot=/var/lib/kubelet \
--set registry=ccr.ccs.tencentyun.com/tcs-infra

helm upgrade --install ssm-platform oci://ccr.ccs.tencentyun.com/tcs-charts/ssm-platform \
--version 2.3.0 -n ssm --create-namespace \
--set tcs.clusterName=tdcc \
--set logCollectedEnable=false \
--set monitor.platform=prometheus \
--set registry=ccr.ccs.tencentyun.com/tcs-infra

helm upgrade --install service-vendors oci://ccr.ccs.tencentyun.com/tcs-charts/service-vendors \
--version 2.3.0 -n ssm --create-namespace \
--set logCollectedEnable=false \
--set monitor.platform=none \
--set tcs.loadBalancerType= \
--set tcs.clusterType=user \
--set registry=ccr.ccs.tencentyun.com/tcs-infra

helm upgrade --install cert-manager oci://ccr.ccs.tencentyun.com/tcs-charts/cert-manager \
--version 1.5.5 -n ssm --create-namespace \
--set installCRDs=true \
--set startupapicheck.enabled=false \
--set image.repository=ccr.ccs.tencentyun.com/tcs-infra/cert-manager-controller \
--set cainjector.repository=ccr.ccs.tencentyun.com/tcs-infra/cert-manager-cainjector \
--set webhook.repository=ccr.ccs.tencentyun.com/tcs-infra/cert-manager-webhook \
--set startupapicheck.repository=ccr.ccs.tencentyun.com/tcs-infra/cert-manager-startupapicheck

