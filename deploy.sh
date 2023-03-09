#!/bin/bash

set -xe

git diff --exit-code
git diff --cached --exit-code

./compile.clj

if ! git diff --exit-code ; then
  git add .
  git commit -m "regenerate"
fi

reapack-index --commit
