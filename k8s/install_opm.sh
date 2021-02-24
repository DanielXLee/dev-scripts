#!/usr/bin/env bash
set -e

VERSION="${1:-v1.16.1}"
OS="$(uname -s)"
ARCH="$(uname -m)"

case $OS in
    "Linux")
        case $ARCH in
        "x86_64")
            ARCH=amd64
            ;;
        "aarch64")
            ARCH=arm64
            ;;
        "armv6" | "armv7l")
            ARCH=armv6l
            ;;
        "armv8")
            ARCH=arm64
            ;;
        .*386.*)
            ARCH=386
            ;;
        esac
        PLATFORM="linux-$ARCH"
    ;;
    "Darwin")
        PLATFORM="darwin-amd64"
    ;;
esac

# Download binary
curl -LO https://github.com/operator-framework/operator-registry/releases/download/${VERSION}/${PLATFORM}-opm
# Install binary
chmod +x ${PLATFORM}-opm && mkdir -p /usr/local/bin/ && cp ${PLATFORM}-opm /usr/local/bin/opm && rm ${PLATFORM}-opm
