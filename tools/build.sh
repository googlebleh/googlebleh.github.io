#!/usr/bin/env bash

docker run \
  --rm \
  --volume="$PWD:/srv/jekyll" \
  -it \
  jekyll/jekyll \
  jekyll build
