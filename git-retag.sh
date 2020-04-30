#!/usr/bin/env bash

tagname=${tagname:-v2.0.0}
git tag -d $tagname
git push origin :refs/tags/$tagname
git tag -a $tagname -m $tagname
git push origin $tagname
