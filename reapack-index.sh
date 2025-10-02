#!/usr/bin/env bash
# dependencies:
# - cmake
# - pandoc
set -e
command -v pandoc
bundle config set path vendor/bundle
bundle install
bundle exec reapack-index "$@"
