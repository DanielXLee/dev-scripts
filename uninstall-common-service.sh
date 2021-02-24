#!/bin/bash
#
# Copyright 2020 IBM Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http:#www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function msg() {
  printf '%b\n' "$1"
}

function success() {
  msg "\33[32m[✔] ${1}\33[0m"
}

function warning() {
  msg "\33[33m[✗] ${1}\33[0m"
}

function error() {
  msg "\33[31m[✘] ${1}\33[0m"
}

function title() {
  msg "\33[34m# ${1}\33[0m"
}

# Sometime delete namespace stuck due to some reousces remaining, use this method to get these
# remaining resources to force delete them.
function get_remaining_resources_from_namespace() {
  local namespace=$1
  local remaining=
  if ${KUBECTL} get namespace ${namespace} &>/dev/null; then
    message=$(${KUBECTL} get namespace ${namespace} -ojson | jq '.status.conditions[]? | select(.type=="NamespaceContentRemaining").message' | sed 's/\"//g' | awk -F': ' '{print $2}')
    [[ "X$message" == "X" ]] && msg "No remaining resources in namespace $namespace" && exit 0
    remaining=$(echo $message | awk '{len=split($0, a, ", ");for(i=1;i<=len;i++)print a[i]" "}' | while read res; do
      echo ${res} | awk '{print $1}'
    done)
  fi
  echo $remaining
}

# Get remaining resource with kinds
function update_remaining_resources() {
  local remaining=$1
  local ns="--all-namespaces"
  local new_remaining=
  [[ "X$2" != "X" ]] && ns="-n $2"
  for kind in ${remaining}; do
    if [[ "X$(${KUBECTL} get ${kind} --all-namespaces --ignore-not-found)" != "X" ]]; then
      new_remaining="${new_remaining} ${kind}"
    fi
  done
  echo $new_remaining
}

function wait_for_deleted() {
  local remaining=${1}
  retries=${2:-10}
  interval=${3:-30}
  index=0
  while true; do
    remaining=$(update_remaining_resources "$remaining")
    if [[ "X$remaining" != "X" ]]; then
      if [[ ${index} -eq ${retries} ]]; then
        error "Timeout for wait all resources deleted"
        return 1
      fi
      sleep $interval
      index=$((index + 1))
      [[ $(($index % 5)) -eq 0 ]] && msg "Still deleting resource ${remaining}, waiting for complete ..."
    else
      break
    fi
  done
}

function wait_for_namespace_deleted() {
  local namespace=$1
  retries=10
  interval=10
  index=0
  while true; do
    if ${KUBECTL} get namespace ${namespace} &>/dev/null; then
      if [[ ${index} -eq ${retries} ]]; then
        error "Timeout for wait namespace deleted"
        return 1
      fi
      sleep $interval
      index=$((index + 1))
      [[ $(($index % 5)) -eq 0 ]] && msg "Still deleting namespace ${namespace}, waiting for complete ..."
    else
      break
    fi
  done
  return 0
}

function delete_operator() {
  local subs=$1
  local namespace=$2
  for sub in ${subs}; do
    csv=$(${KUBECTL} get sub ${sub} -n ${namespace} -o=jsonpath='{.status.installedCSV}' --ignore-not-found)
    if [[ "X${csv}" != "X" ]]; then
      msg "Delete operator ${sub} from namespace ${namespace}"
      ${KUBECTL} delete csv ${csv} -n ${namespace} --ignore-not-found
      ${KUBECTL} delete sub ${sub} -n ${namespace} --ignore-not-found
    fi
  done
}

function delete_operand() {
  local crds=$1
  for crd in ${crds}; do
    if ${KUBECTL} api-resources | grep $crd &>/dev/null; then
      for ns in $(oc get $crd --no-headers --all-namespaces --ignore-not-found | awk '{print $1}' | sort -n | uniq); do
        crs=$(${KUBECTL} get ${crd} --no-headers --ignore-not-found -n ${ns} 2>/dev/null | awk '{print $1}')
        if [[ "X${crs}" != "X" ]]; then
          msg "Deleting ${crd} from namespace ${ns}"
          ${KUBECTL} delete ${crd} --all -n ${ns} --ignore-not-found &
        fi
      done
    fi
  done
}

function delete_operand_finalizer() {
  local crds=$1
  for crd in ${crds}; do
    for ns in $(oc get ${crd} --no-headers --all-namespaces --ignore-not-found | awk '{print $1}' | sort -n | uniq); do
      crs=$(${KUBECTL} get ${crd} --no-headers --ignore-not-found -n ${ns} 2>/dev/null | awk '{print $1}')
      for cr in ${crs}; do
        msg "Removing the finalizers for resource: ${crd}/${cr}"
        ${KUBECTL} patch ${crd} ${cr} -n ${ns} --type="json" -p '[{"op": "remove", "path":"/metadata/finalizers"}]' 2>/dev/null
      done
    done
  done
}

function delete_unavailable_apiservice() {
  rc=0
  apis=$(${KUBECTL} get apiservice | grep False | awk '{print $1}')
  if [ "X${apis}" != "X" ]; then
    warning "Found some unavailable apiservices, deleting ..."
    for api in ${apis}; do
      msg "${KUBECTL} delete apiservice ${api}"
      ${KUBECTL} delete apiservice ${api}
      if [[ "$?" != "0" ]]; then
        error "Delete apiservcie ${api} failed"
        rc=$((rc + 1))
        continue
      fi
    done
  fi
  return $rc
}

function delete_rbac_resource() {
  ${KUBECTL} delete ClusterRoleBinding ibm-common-service-webhook secretshare-ibm-common-services $(${KUBECTL} get ClusterRoleBinding | grep nginx-ingress-clusterrole | awk '{print $1}') --ignore-not-found
  ${KUBECTL} delete ClusterRole ibm-common-service-webhook secretshare nginx-ingress-clusterrole --ignore-not-found
  ${KUBECTL} delete RoleBinding ibmcloud-cluster-info ibmcloud-cluster-ca-cert -n kube-public --ignore-not-found
  ${KUBECTL} delete Role ibmcloud-cluster-info ibmcloud-cluster-ca-cert -n kube-public --ignore-not-found
  ${KUBECTL} delete scc nginx-ingress-scc --ignore-not-found
}

function force_delete() {
  local namespace=$1
  local remaining=$(get_remaining_resources_from_namespace "$namespace")
  if [[ "X$remaining" != "X" ]]; then
    warning "Some resources remaining: $remaining"
    msg "Delete finalizer for these resources ..."
    delete_operand_finalizer "${remaining}"
    wait_for_deleted "${remaining}" 5 10
  fi
}

#-------------------------------------- Clean UP --------------------------------------#
COMMON_SERVICES_NS=${COMMON_SERVICES_NS:-ibm-common-services}
KUBECTL=$(which kubectl 2>/dev/null)
[[ "X$KUBECTL" == "X" ]] && error "kubectl: command not found" && exit 1
step=0

# Before uninstall common services, we should delete some unavailable apiservice
delete_unavailable_apiservice

title "[$step] Deleting ibm-common-service-operator ..."
for sub in $(${KUBECTL} get sub --all-namespaces --ignore-not-found | awk '{if ($3 =="ibm-common-service-operator") print $1"/"$2}'); do
  namespace=$(echo $sub | awk -F'/' '{print $1}')
  name=$(echo $sub | awk -F'/' '{print $2}')
  delete_operator "$name" "$namespace"
done
step=$((step + 1))

title "[$step] Deleting common services operand from all namespaces ..."
delete_operand "OperandRequest" && wait_for_deleted "OperandRequest" 50 30
delete_operand "CommonService OperandRegistry OperandConfig"
delete_operand "NamespaceScope" && wait_for_deleted "NamespaceScope"
step=$((step + 1))

# Delete the previous version ODLM operator
if ${KUBECTL} get sub operand-deployment-lifecycle-manager-app -n openshift-operators &>/dev/null; then
  title "[$step] Deleting ODLM Operator ..."
  delete_operator "operand-deployment-lifecycle-manager-app" "openshift-operators"
  step=$((step + 1))
fi

title "[$step] Deleting RBAC resources ..."
delete_rbac_resource
step=$((step + 1))

title "[$step] Deleting webhook ..."
${KUBECTL} delete ValidatingWebhookConfiguration -l 'app=ibm-cert-manager-webhook' --ignore-not-found
${KUBECTL} delete MutatingWebhookConfiguration ibm-common-service-webhook-configuration --ignore-not-found
step=$((step + 1))

title "[$step] Deleting namespace ${COMMON_SERVICES_NS} ..."
${KUBECTL} delete namespace ${COMMON_SERVICES_NS} --ignore-not-found &
if wait_for_namespace_deleted ${COMMON_SERVICES_NS}; then
  success "Common Services uninstall finished and successfull."
  exit 0
fi
step=$((step + 1))

title "[$step] Force delete remaining resources ..."
delete_unavailable_apiservice
force_delete "$COMMON_SERVICES_NS" && success "Common Services uninstall finished and successfull." && exit 0
error "Something wrong, woooow ......, checking namespace detail:"
${KUBECTL} get namespace ${COMMON_SERVICES_NS} -oyaml
exit 1
