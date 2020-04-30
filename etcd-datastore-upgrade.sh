#!/usr/bin/env bash
# See detail steps: https://docs.projectcalico.org/v3.0/getting-started/kubernetes/upgrade/

certs_dir="/etc/cfc/conf/etcd"
etcdKeyFile="${certs_dir}/client-key.pem"
etcdCertFile="${certs_dir}/client.pem"
etcdCACertFile="${certs_dir}/ca.pem"
etcdEndpoints="https://9.111.255.20:4001"

cat > etcdv2.yaml <<EOF
apiVersion: v1
kind: calicoApiConfig
metadata:
spec:
  datastoreType: "etcdv2"
  etcdEndpoints: $etcdEndpoints
  etcdKeyFile: $etcdKeyFile
  etcdCertFile: $etcdCertFile
  etcdCACertFile: $etcdCACertFile

EOF

cat > etcdv3.yaml <<EOF
apiVersion: projectcalico.org/v3
kind: CalicoAPIConfig
metadata:
spec:
  datastoreType: "etcdv3"
  etcdEndpoints: $etcdEndpoints
  etcdKeyFile: $etcdKeyFile
  etcdCertFile: $etcdCertFile
  etcdCACertFile: $etcdCACertFile

EOF

if [[ ! -f /usr/local/bin/calico-upgrade ]]; then
  wget https://github.com/projectcalico/calico-upgrade/releases/download/v1.0.3/calico-upgrade
  chmod +x calico-upgrade
  mv calico-upgrade /user/local/bin/
fi
# Test the migration
#calico-upgrade dry-run --apiconfigv1 etcdv2.yaml --apiconfigv3 etcdv3.yaml

# Migration data
# You are about to start the migration of Calico v1 data format to Calico v3 data
# format. During this time and until the upgrade is completed Calico networking
# will be paused - which means no new Calico networked endpoints can be created.
# No Calico configuration should be modified using calicoctl during this time.
calico-upgrade start --apiconfigv1 etcdv2.yaml --apiconfigv3 etcdv3.yaml --no-prompts

# Complete calico upgrade, run following command after calico upgraded
# You are about to complete the upgrade process to Calico v3. At this point, the
# v1 format data should have been successfully converted to v3 format, and all
# calico/node instances and orchestrator plugins (e.g. CNI) should be running
# Calico v3.x.
#calico-upgrade complete --apiconfigv1 etcdv2.yaml --apiconfigv3 etcdv3.yaml --no-prompts
