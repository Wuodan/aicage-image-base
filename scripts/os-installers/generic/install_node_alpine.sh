#!/usr/bin/env bash
set -euo pipefail

# Prefer distro packages on Alpine to avoid missing musl tarballs.
# xdg-utils: provides xdg-open; required by npm-installed CLI agents (e.g. droid) to open auth/docs URLs
apk add --no-cache \
  nodejs-current \
  npm \
  xdg-utils


npm config set prefix /usr/local
