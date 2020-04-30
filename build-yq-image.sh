#!/usr/bin/env bash
# A lightweight and portable command-line YAML processor
# The aim of the project is to be the jq or sed of yaml files.
# Project link: https://github.com/mikefarah/yq
# Docker run usage: https://github.com/mikefarah/yq#run-with-docker
# Oneshot use:
# docker run --rm -v ${PWD}:/workdir mikefarah/yq yq [flags] <command> FILE...

mkdir github
cd github/
apt install git -y
git clone https://github.com/mikefarah/yq.git
cd yq/
git checkout v2.4.0
./scripts/publish-docker.sh
