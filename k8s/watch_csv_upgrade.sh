#!/bin/bash
target_ver=$1
while true; do
  csv_ver=$(oc get csv | sed 1d | awk '{print $4}')
  if [[ "$csv_ver" == "$target_ver" ]]; then
    echo "[`date +"%y-%m-%d %H:%M:%S"`] Wow..., operator has auto upgraded to the version $target_ver"
    break
  else
    echo "[`date +"%y-%m-%d %H:%M:%S"`] Operator does not upgrade, the version still is $csv_ver, sleeping ..."
    sleep 60
  fi 
done
