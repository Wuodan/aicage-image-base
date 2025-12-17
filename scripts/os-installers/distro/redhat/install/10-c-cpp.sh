#!/usr/bin/env bash
set -euo pipefail

dnf -y group install development-tools
dnf -y install \
  clang \
  cmake \
  gdb \
  lld \
  lldb \
  ltrace \
  ninja-build \
  openssl-devel \
  pkgconf-pkg-config \
  strace \
  valgrind \
  zlib-devel
