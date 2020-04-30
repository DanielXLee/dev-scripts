#!/usr/bin/env bash
function pull_images() {
  echo "Pulling images"
  echo -e "${IMAGES}" | xargs -P10 -n1 -i bash -c "docker pull $SOURCE_REPO/{}"
}

function push_images() {
  echo "Pushing images to new repo"
  echo -e "${IMAGES}" | xargs -P10 -n1 -i bash -c " \
  docker tag ${SOURCE_REPO}/${IMAGE} ${TARGET_REPO}/{} \
  docker push ${TARGET_REPO}/{}"
  for IMAGE in $IMAGES; do
    docker tag ${SOURCE_REPO}/${IMAGE} ${TARGET_REPO}/${IMAGE}
    docker push ${TARGET_REPO}/${IMAGE}
  done
}

function build_multi() {
  echo "Build multiarch"
  for IMAGE in $IMAGES; do
  ./manifest-tool push from-args \
      --platforms linux/amd64,linux/ppc64le,linux/s390x \
      --template ${TARGET_REPO}/${IMAGE//:/-ARCH:} \
      --target ${TARGET_REPO}/$IMAGE \
      --ignore-missing
  done
}

function manifest_tool() {
  echo "Install manifest-tool"
  local ARCH=$(uname -m)
  [[ "$ARCH" == "x86_64" ]] && ARCH="amd64"
  if [[ ! -f manifest-tool ]]; then
    wget https://github.com/estesp/manifest-tool/releases/download/v0.7.0/manifest-tool-linux-${ARCH} -O manifest-tool
    chmod +x manifest-tool
  fi
}

# image list TBD

IMAGES=$(cat images.txt | sort -u)
# integration, edge, stable
REPO_TYPE="integration"
if [[ "$REPO_TYPE" == "integration" ]]; then
  SOURCE_REPO=${SOURCE_REPO:-hyc-cloud-private-${REPO_TYPE}-docker-local.artifactory.swg-devops.com/ibmcom}
else
  SOURCE_REPO=${SOURCE_REPO:-hyc-cloud-private-${REPO_TYPE}-docker-local.artifactory.swg-devops.com/ibmcom-amd64}
fi
TARGET_REPO=${TARGET_REPO:-registry.mixhub.cn/upgrade-test}
pull_images
push_images
manifest_tool
build_multi
