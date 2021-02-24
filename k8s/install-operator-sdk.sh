#!/bin/bash

echo "Installing Operator SDK"

RELEASE_VERSION=${RELEASE_VERSION:-v0.17.0}
ARCH=$(uname -m)
# Download binary
curl -LO https://github.com/operator-framework/operator-sdk/releases/download/${RELEASE_VERSION}/operator-sdk-${RELEASE_VERSION}-${ARCH}-linux-gnu
# Install binary
chmod +x operator-sdk-${RELEASE_VERSION}-${ARCH}-linux-gnu && mkdir -p /usr/local/bin/ && cp operator-sdk-${RELEASE_VERSION}-${ARCH}-linux-gnu /usr/local/bin/operator-sdk && rm operator-sdk-${RELEASE_VERSION}-${ARCH}-linux-gnu
