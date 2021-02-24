#!/bin/bash

function output() {
  local res_limit=$1
  local version=$2
  echo "In version \`$version\`" >> $resourcelimit_output
  echo >> $resourcelimit_output
  echo '```yaml' >> $resourcelimit_output
  echo "$res_limit" >> $resourcelimit_output
  echo '```' >> $resourcelimit_output
  echo >> $resourcelimit_output
}

function switch_env_to () {
  local env_ctx=$1
  oc config use-context $env_ctx &>/dev/null
}

# Support resource type: Deployment, DaemonSet and StatefulSet
function get_res_limit() {
  local res_type=$1

  switch_env_to $env_ctx_1
  env_1_res_names=$(oc -n $namespace --no-headers=true get $res_type | awk '{print $1}')

  switch_env_to $env_ctx_2
  env_2_res_names=$(oc -n $namespace --no-headers=true get $res_type | awk '{print $1}')
  res_names=$(echo "$env_1_res_names $env_2_res_names" | sort -n | uniq)

  echo "## Compare $res_type resources limit in version $env_version_1 and $env_version_2" >> $resourcelimit_output
  echo >> $resourcelimit_output
  for res_name in $(echo "$res_names");
  do
    switch_env_to $env_ctx_1
    env_1_res_limit=$(oc -n $namespace get $res_type $res_name -ojson | jq '.spec.template.spec' | jq '.initContainers[]?, .containers[]? | {container: .name, resources: .resources}' | yq r -P - 2>/dev/null)

    switch_env_to $env_ctx_2
    env_2_res_limit=$(oc -n $namespace get $res_type $res_name -ojson | jq '.spec.template.spec' | jq '.initContainers[]?, .containers[]? | {container: .name, resources: .resources}' | yq r -P - 2>/dev/null)

    [[ "$env_1_res_limit" == "$env_2_res_limit" ]] && continue
    echo "### $res_type \`$res_name\` resource limits" >> $resourcelimit_output
    echo >> $resourcelimit_output
    output "$env_1_res_limit" "$env_version_1"
    output "$env_2_res_limit" "$env_version_2"
  done  
}

#--------------------------------- Main ---------------------------------#
resourcelimit_output=resourcelimit_output.md
namespace=ibm-common-services
ctx_1="default/api-stemma-cp-fyre-ibm-com:6443/kube:admin"
ctx_2="default/api-xl-odlm-test-cp-fyre-ibm-com:6443/kube:admin"

env_ctx_1=$ctx_1
env_ctx_2=$ctx_2
env_version_1=1.1
env_version_2=1.2
[[ -f ./$resourcelimit_output ]] && >$resourcelimit_output
echo "# Compare Resource Limit in Different Common Services Version" >>$resourcelimit_output
echo >>$resourcelimit_output
get_res_limit "Deployment"
get_res_limit "DaemonSet"
get_res_limit "StatefulSet"
