#!/usr/bin/env bash
# After root ca changed, we need to reload all the defualt-token and related pods 

kubectl get secret --no-headers --all-namespaces -o=custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace | grep default-token | while read token; do
  secret_name=$(echo $token | awk '{print $1}')
  secret_namespace=$(echo $token | awk '{print $2}')
  echo "-----------------------------------------------------------------------"
  echo "|                          Reload Services"
  echo "|         Token: ${secret_name}"
  echo "|     Namespace: ${secret_namespace}"
  echo "-----------------------------------------------------------------------"
  echo "Deleteing default token ..."
  kubectl -n ${secret_namespace} delete secret ${secret_name} &>/dev/null
  echo "Reloading services ..."
  kubectl -n ${secret_namespace} get po --field-selector=status.phase!=Completed,status.phase!=Succeeded,status.phase!=Unknow --no-headers -o=custom-columns=NAME:.metadata.name | while read pod; do
      secret_used=$(kubectl -n ${secret_namespace} get po ${pod} -oyaml | grep "secretName: default-token" &>/dev/null || echo no && echo yes)
      if [[ "$secret_used" == "yes" ]]; then
        echo "    - Restarting pod ${pod} ..."
        kubectl -n ${secret_namespace} delete po ${pod} --grace-period=0 --force &>/dev/null
      else
        echo "    - Pod ${pod} does not use default token"
      fi
  done
  echo
done
