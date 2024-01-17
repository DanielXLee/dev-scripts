#!/bin/bash

docker tag ghcr.io/clusternet/clusternet-hub-amd64:v0.7.1 ccr.ccs.tencentyun.com/tkeimages/clusternet-hub:v0.7.1
docker tag ghcr.io/clusternet/clusternet-scheduler-amd64:v0.7.1 ccr.ccs.tencentyun.com/tkeimages/clusternet-scheduler:v0.7.1
docker tag ghcr.io/clusternet/clusternet-agent-amd64:v0.7.1 ccr.ccs.tencentyun.com/tkeimages/clusternet-agent:v0.7.1

docker push ccr.ccs.tencentyun.com/tkeimages/clusternet-hub:v0.7.1
docker push ccr.ccs.tencentyun.com/tkeimages/clusternet-scheduler:v0.7.1
docker push ccr.ccs.tencentyun.com/tkeimages/clusternet-agent:v0.7.1


docker tag ghcr.io/clusternet/clusternet-hub-amd64:v0.7.1 ccr.ccs.tencentyun.com/danielxxli/clusternet-hub:v0.7.1
docker tag ghcr.io/clusternet/clusternet-scheduler-amd64:v0.7.1 ccr.ccs.tencentyun.com/danielxxli/clusternet-scheduler:v0.7.1
docker tag ghcr.io/clusternet/clusternet-agent-amd64:v0.7.1 ccr.ccs.tencentyun.com/danielxxli/clusternet-agent:v0.7.1

docker push ccr.ccs.tencentyun.com/danielxxli/clusternet-hub:v0.7.1
docker push ccr.ccs.tencentyun.com/danielxxli/clusternet-scheduler:v0.7.1
docker push ccr.ccs.tencentyun.com/danielxxli/clusternet-agent:v0.7.1

