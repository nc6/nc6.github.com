#!/bin/bash

COMMIT_SHA=$(cat .git/refs/heads/source)
DATE=$(date)

rm -rf _deploy/*
cp -R _site/* _deploy/

cd _deploy 
git add .
git commit -am "Updated site on $DATE.
Source commit id: $COMMIT_SHA"
git push origin

cd ..

