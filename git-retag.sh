#!/usr/bin/env bash

tagname=${tagname:-olm-v0.17.0}
git tag -d $tagname
git push origin :refs/tags/$tagname
git tag -a $tagname -m $tagname
git push origin $tagname
