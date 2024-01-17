#!/bin/bash

# 定义帮助函数
help() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -a, --app-id            App ID"
    echo "  -u, --uin               Uin"
    echo "  -r, --region            Region"
    echo "  -f --filter              Filter"
    echo "  -h, --help              Show this help message and exit"
}

# 设置默认值
app_id=""
uin=""
region=""
filters=("{\"Name\":\"pool\",\"Values\":[\"qcloud\"]}")

# 解析参数
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -a|--app-id)
        app_id="$2"
        shift
        shift
        ;;
        -u|--uin)
        uin="$2"
        sub_account_uin="$2"
        shift
        shift
        ;;
        -r|--region)
        region="$2"
        shift
        shift
        ;;
        -f|--filter)
        filter_key="$2"
        filter_value="$3"
        IFS=',' read -ra filter_values <<< "$filter_value"
        vals=()
        for fv in "${filter_values[@]}"; do
          vals+=(\"${fv}\")
        done
        filters+=("{\"Name\":\"${filter_key}\",\"Values\":[${vals[@]}]}")
        shift
        shift
        shift
        ;;
        -h|--help)
        help
        exit 0
        ;;
        *)
        echo "Unknown option: $1"
        help
        exit 1
        ;;
    esac
done
filters_json="["$(echo "${filters[@]}" | sed 's/ /,/g')"]"

# 检查是否已安装 jq
if ! command -v jq &> /dev/null
then
    echo "jq未安装。请先安装jq（https://stedolan.github.io/jq/download/）然后重试。"
    exit 1
fi

# 定义查询 CVM 实例配额的函数
describe_cvm_quota() {
    local url="http://bj.cvmapiv3.tencentyun.com:8520"
    response=$(curl -s "${url}" -d'{"AppId":'${app_id}',"Uin":"'${uin}'","SubAccountUin":"'${sub_account_uin}'","Region":"'${region}'","Action":"DescribeZoneInstanceConfigInfos","Version":"2018-01-01","Language":"","RequestSource":"EKS","Filters":'${filters_json}'}')
    if [[ ${response} =~ "Error" ]]; then
        echo "请求失败。请检查参数并重试。"
        exit 1
    fi
    echo "------------------------------------------ CVM Quota ------------------------------------------"
    echo "${response}" | jq '.[].InstanceTypeQuotaSet[] | {Zone: .Zone, InstanceType: .InstanceType, InstanceChargeType: .InstanceChargeType, Status: .Status, InstanceQuota: .InstanceQuota}'
    echo "${response}" | jq '.Response | {RequestId: .RequestId}'
    echo
}

# 定义查询 CXM 实例配额的函数
describe_cxm_quota() {
    local url="http://bj.cxmapi.tencentyun.com:8521"
    response=$(curl -s "${url}" -d'{"AppId":'${app_id}',"Uin":"'${uin}'","SubAccountUin":"'${sub_account_uin}'","Region":"'${region}'","Action":"DescribeZoneInstanceTypeInventory","Version":"2017-03-12","Language":"","RequestSource":"EKS","Filters":'${filters_json}',"UseLargeScaleCpuRes":true}')

    if [[ ${response} =~ "Error" ]]; then
        echo "请求失败。请检查参数并重试。"
        exit 1
    fi
    echo "------------------------------------------ CXM Quota ------------------------------------------"
    echo "${response}" | jq '.[].InstanceTypeQuotaSet[] | {Zone: .Zone, InstanceType: .InstanceType, Inventory: .Inventory, ReservedInventory: .ReservedInventory}'
    echo "${response}" | jq '.Response | {RequestId: .RequestId}'
    echo
}

describe_cvm_quota
describe_cxm_quota
