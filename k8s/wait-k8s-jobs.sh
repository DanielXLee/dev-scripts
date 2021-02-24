#!/bin/bash
# Licensed Materials - Property of IBM
# (C) Copyright IBM Corporation 2016, 2020. All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#

# Variables
B='\e[34m' # Blue
M='\e[35m'   # Magenta
Y='\e[33m' # Yellow
G='\e[32m' # Green
R='\e[31m' # Red
S='\e[0m'  # Reset

function msg() {
  printf '%b\n' "$1"
}

function success() {
  msg "${G}[✔] ${1}${S}"
}

function warning() {
  msg "${Y}[✗] ${1}${S}"
}

function error() {
  msg "${R}[✘] ${1}${S}"
}

function title() {
  msg "${B}# ${1}${S}"
}

function timer() {
  msg=$1
  while true; do
    for bar in '\' '|' '/' '-'; do
      sleep 1 &
      printf "\r.: $Y$msg$S... $G%s$S" $bar
      wait
    done
  done
}

function wait_job_done() {
  job_name=$1
  retries=${2:-100}
  index=0
  wait=30
  (timer "Job ${job_name} is running, waiting for complete") >&2 &
  timer_job_pid="$!"
  disown $timer_job_pid
  while true; do
    status=$(check_job_status "${job_name}")
    if [[ "${status}" == "NotFound" || "${status}" == "running" ]]; then
      if [[ ${index} -eq ${retries} ]]; then
        kill "${timer_job_pid}" >/dev/null 2>&1
        echo
        error "Timeout for wait job ${job_name} complete"
        return 1
      fi
      sleep $wait
      index=$((index + 1))
    elif [[ "${status}" == "failed" ]]; then
      kill "${timer_job_pid}" >/dev/null 2>&1
      echo
      error "Job ${job_name} failed"
      return 1
    elif [[ "${status}" == "succeeded" ]]; then
      kill "${timer_job_pid}" >/dev/null 2>&1
      echo
      success "Job ${job_name} succeeded"
      return 0
    fi
  done
}

function check_job_status() {
  job_name=$1
  job_status=$(oc -n ${namespace} get job ${job_name} -o=jsonpath='{.status.active}{"|"}{.status.failed}{"|"}{.status.succeeded}{"|"}{.spec.completions}' 2>/dev/null)
  [[ "X${job_status}" == "X" ]] && echo "NotFound" && exit 0

  active_num=$(echo ${job_status} | awk -F'|' '{print $1}')
  failed_num=$(echo ${job_status} | awk -F'|' '{print $2}')
  succeeded_num=$(echo ${job_status} | awk -F'|' '{print $3}')
  completion_num=$(echo ${job_status} | awk -F'|' '{print $4}')

  if [[ "X${failed_num}" != "X" ]]; then
    echo "failed"
  elif [[ "X${active_num}" != "X" ]]; then
    echo "running"
  elif [[ "${succeeded_num}" == "${completion_num}" ]]; then
    echo "succeeded"
  fi
}

function run_job() {
  job_name=$1
  job_yaml_file=$2
  retries=${3:-100}
  status=$(check_job_status "${job_name}")
  if [[ "${status}" == "NotFound" ]]; then
    oc create -f ${job_yaml_file}.yaml
    msg "Check job logs with command: ${M}oc -n ${namespace} logs job/${job_name}${N}"
    wait_job_done "${job_name}" ${retries}
    return $?
  elif [[ "${status}" == "failed" ]]; then
    read -rp "Job ${job_name} run failed, do you want continue? [yes/no]: " go
    go=${go:-no}
    case "${go}" in
    "Y"* | "y"*)
      read -rp "Do you want to skip or rerun the failed job ${job_name}? [rerun/skip]: " gopath
      gopath=${gopath:-rerun}
      case "${gopath}" in
      "r"*)
        oc delete -f ${job_yaml_file}.yaml --ignore-not-found
        sleep 10
        oc create -f ${job_yaml_file}.yaml
        msg "Check job logs with command: ${M}oc -n ${namespace} logs job/${job_name}${N}"
        wait_job_done "${job_name}" ${retries}
        return $?
        ;;
      *)
        failed_job_num=$((failed_job_num + 1))
        warning "Failed job ${job_name} skipped, continue next job..."
        ;;
      esac
      ;;
    *)
      warning "Aborting ..."
      return 1
      ;;
    esac
  elif [[ "${status}" == "running" ]]; then
    msg "Check job logs with command: ${M}oc -n ${namespace} logs job/${job_name}${N}"
    wait_job_done "${job_name}" ${retries}
    return $?
  else
    success "Job ${job_name} succeeded"
  fi
}

job_name=""
job_namespace=""
while [ "$#" -gt "0" ]
do
	case "$1" in
	"-h"|"--help")
		usage
		exit 0
		;;
	"-n")
		shift
		job_name="$1"
		;;
	"-ns")
		shift
		job_namespace="$1"
		;;
	*)
		error "Try \`$0 --help' for more information"
		;;
	esac
	shift
done

#---------------------------- Main ---------------------------#
namespace="kube-system"
job_name=${job_name:}
failed_job_num=0


  title "Run the cs3.2.4 init job to create a volume that will be used for backup"
  # exit script when job run failed
  run_job "cs324-init" "cs3.2.4-init" 10 || exit 1

  title "Backup Common Services 3.2.4 resource"
  run_job "cs324-backup" "cs3.2.4-backup" || exit 1

  title "Uninstall Common Services 3.2.4"
  run_job "cs324-uninstall" "cs3.2.4-uninstall" || exit 1

  title "Install Common Services 3.4 and restore information from 3.2.4"
  run_job "cs34-restore" "cs3.4-restore" 200 || exit 1

