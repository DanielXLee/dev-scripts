#!/usr/bin/env bash

echo "Install protoc package"
PROTOC_ZIP=protoc-3.12.4-linux-x86_64.zip
curl -OL https://github.com/protocolbuffers/protobuf/releases/download/v3.12.4/$PROTOC_ZIP
sudo unzip -o $PROTOC_ZIP -d /usr/local bin/protoc
sudo unzip -o $PROTOC_ZIP -d /usr/local 'include/*'
rm -f $PROTOC_ZIP

echo "Install revive go package"
go get -u github.com/mgechev/revive
cp /root/go/bin/revive /root/go/src/git.code.oa.com/tke/tke/output/tools


