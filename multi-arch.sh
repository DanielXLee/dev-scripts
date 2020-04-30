#!/bin/bash

REGISTRY=${REGISTRY:-danielxlee}
# If have multi images, use empty split them, like: "curl:latest yq:latest"
IMAGES=${IMAGES:-}

function build_multi() {
  echo ">> 2: Create manifest list against a specified registry"

  for IMAGE in $IMAGES; do
    cat > registry.yaml <<EOF
image: ${REGISTRY}/${IMAGE}
manifests:
  -
    image: ${REGISTRY}/${IMAGE//:/-ppc64le:}
    platform:
      architecture: ppc64le
      os: linux
  -
    image: ${REGISTRY}/${IMAGE//:/-amd64:}
    platform:
      architecture: amd64
      os: linux
  -
    image: ${REGISTRY}/${IMAGE//:/-s390x:}
    platform:
      architecture: s390x
      os: linux
EOF
  ./manifest-tool push from-spec registry.yaml
  done

}

function manifest_tool() {
  ARCH=$(uname -m | sed 's/x86_64/amd64/g')
  if [[ ! -f manifest-tool ]]; then
    echo ">> 1: Install manifest-tool"
    wget https://github.com/estesp/manifest-tool/releases/download/v0.7.0/manifest-tool-linux-${ARCH} -O manifest-tool
    chmod +x manifest-tool
  fi
}

#------------------------ Main ------------------------#
[[ "X$IMAGES" == "X" ]] && echo "Missing images list, export IMAGES='a:1.0 b:2.0' before run script." && exit 0
manifest_tool
build_multi
