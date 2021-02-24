#!/usr/bin/env bash

goversion=$1

pushd ~/go
rm -rf bin
ln -s ~/go_${goversion}_bin/ bin
popd

 #export PATH="/usr/local/opt/go@1.13/bin:$PATH"
