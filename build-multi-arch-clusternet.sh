#!/bin/bash

docker push blackholex/clusternet-scheduler-s390x:v0.7.1
docker push blackholex/clusternet-scheduler-ppc64le:v0.7.1
docker push blackholex/clusternet-scheduler-arm64:v0.7.1
docker push blackholex/clusternet-scheduler-arm:v0.7.1
docker push blackholex/clusternet-scheduler-amd64:v0.7.1
docker push blackholex/clusternet-scheduler-386:v0.7.1
docker push blackholex/clusternet-hub-s390x:v0.7.1
docker push blackholex/clusternet-hub-ppc64le:v0.7.1
docker push blackholex/clusternet-hub-arm64:v0.7.1
docker push blackholex/clusternet-hub-arm:v0.7.1
docker push blackholex/clusternet-hub-amd64:v0.7.1
docker push blackholex/clusternet-hub-386:v0.7.1
docker push blackholex/clusternet-agent-s390x:v0.7.1
docker push blackholex/clusternet-agent-ppc64le:v0.7.1
docker push blackholex/clusternet-agent-arm64:v0.7.1
docker push blackholex/clusternet-agent-arm:v0.7.1
docker push blackholex/clusternet-agent-amd64:v0.7.1
docker push blackholex/clusternet-agent-386:v0.7.1

docker manifest create docker.io/blackholex/clusternet-agent:v0.7.1 \
--amend docker.io/blackholex/clusternet-agent-amd64:v0.7.1 \
--amend docker.io/blackholex/clusternet-agent-386:v0.7.1 \
--amend docker.io/blackholex/clusternet-agent-arm:v0.7.1 \
--amend docker.io/blackholex/clusternet-agent-arm64:v0.7.1 \
--amend docker.io/blackholex/clusternet-agent-ppc64le:v0.7.1 \
--amend docker.io/blackholex/clusternet-agent-s390x:v0.7.1

docker manifest push docker.io/blackholex/clusternet-agent:v0.7.1
