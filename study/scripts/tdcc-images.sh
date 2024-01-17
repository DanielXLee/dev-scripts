#!/bin/bash

docker tag tkestack/tke-platform-controller-amd64:v1.18.5 ccr.ccs.tencentyun.com/danielxxli/tke-platform-controller:v1.18.5
docker tag tkestack/tke-platform-api-amd64:v1.18.5 ccr.ccs.tencentyun.com/danielxxli/tke-platform-api:v1.18.5
# docker tag tkestack/tke-application-controller-amd64:v1.18.5 ccr.ccs.tencentyun.com/danielxxli/tke-application-controller:v1.18.5
# docker tag tkestack/tke-application-api-amd64:v1.18.5 ccr.ccs.tencentyun.com/danielxxli/tke-application-api:v1.18.5


docker push ccr.ccs.tencentyun.com/danielxxli/tke-platform-controller:v1.18.5
docker push ccr.ccs.tencentyun.com/danielxxli/tke-platform-api:v1.18.5
# docker push ccr.ccs.tencentyun.com/danielxxli/tke-application-controller:v1.18.5
# docker push ccr.ccs.tencentyun.com/danielxxli/tke-application-api:v1.18.5

docker pull ccr.ccs.tencentyun.com/danielxxli/tke-platform-controller-amd64:v1.18.5
docker pull ccr.ccs.tencentyun.com/danielxxli/tke-platform-api-amd64:v1.18.5
docker pull ccr.ccs.tencentyun.com/danielxxli/tke-application-controller-amd64:v1.18.5
docker pull ccr.ccs.tencentyun.com/danielxxli/tke-application-api-amd64:v1.18.5
