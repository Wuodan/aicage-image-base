#!/usr/bin/env bash
set -euo pipefail

dnf -y install \
  ant \
  gradle \
  java-latest-openjdk-devel \
  maven \
  protobuf-compiler
