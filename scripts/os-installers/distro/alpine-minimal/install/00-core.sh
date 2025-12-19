#!/usr/bin/env bash
set -euo pipefail

apk add --no-cache \
  bash \
  curl \
  libc-utils \
  git \
  patch \
  shadow \
  tini
