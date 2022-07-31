#!/bin/bash

set -e

if ! git diff --exit-code ; then
  echo "ERROR: Unchecked changes"
  exit 1
fi
if ! git diff --cached --exit-code ; then
  echo "ERROR: Uncommitted changes"
fi

./compile.clj

if ! git diff --exit-code ; then
  git add .
  git commit -m "regenerate"
fi

reapack-index --commit "$@"
