#!/bin/bash
# 例如我们要更新Module name是infrastructureManagement
# config name是ibm-management-im-install 的enabled为false

module_name=infrastructureManagement
config_name=ibm-management-im-install

i=0
for module in $(cat test.json | jq -c '.spec.pakModules[]'); do
  j=0
  if [[ $(echo $module | jq '.name') == "\"$module_name\"" ]]; then
    for config in $(echo $module | jq -c '.config[]'); do
      if [[ $(echo $config | jq '.name') == "\"$config_name\"" ]]; then
        jq '.spec.pakModules['$i'].config['$j'].enabled = false' test.json | yq r -P - > new_obj.yaml
      fi
      j=$((j + 1))
    done
  fi
  i=$(( i + 1 ))
done

# config=$(cat test.json| jq '.spec.pakModules[] | select(.name=="infrastructureManagement").config')
# new_config=$(echo $config | jq '.[] | select(.name=="ibm-management-im-install").enabled=false')
