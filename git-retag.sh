#!/usr/bin/env bash

tagname=v0.14.0
msg="bump clusternet syncer version to ${tagname}"
git tag -d $tagname
git push origin :refs/tags/$tagname
git tag -a $tagname -m $msg
git push origin $tagname


tagname=v0.15.4
msg="bump clusternet version to ${tagname}"
git tag -d $tagname
git push origin :refs/tags/$tagname
git tag -a $tagname -m $msg
git push origin $tagname


tagname=v1.1.22
msg="bump tdcc platform version to ${tagname}"
git tag -a $tagname -m $msg
git push origin $tagname

tagname=v1.1.20
msg="bump tdcc cloud gw version to ${tagname}"
git tag -d $tagname
git push origin :refs/tags/$tagname
git tag -a $tagname -m $msg
git push origin $tagname


tagname=release-0.7.24
msg="bump anywhere and clusternet chart version"
git tag -d $tagname
git push origin :refs/tags/$tagname
git tag -a $tagname -m $msg
git push origin $tagname

tagname=v0.1.0
msg="bump tdcc-webhook-manager version"
git tag -d $tagname
git push origin :refs/tags/$tagname
git tag -a $tagname -m $msg
git push origin $tagname

tagname=v0.9.44-rc2
msg="bump tke-node-server version"
git tag -d $tagname
git push origin :refs/tags/$tagname
git tag -a $tagname -m $msg
git push origin $tagname


tagname=v0.9.35-rc1
msg="bump tke-node-cloud-gw version"
git tag -d $tagname
git push origin :refs/tags/$tagname
git tag -a $tagname -m $msg
git push origin $tagname
