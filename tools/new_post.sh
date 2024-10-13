#!/usr/bin/env bash

docker run \
  --volume="$PWD:/srv/jekyll" \
  -it \
  jekyll/jekyll \
  jekyll post "nginx and Let's Encrypt"
