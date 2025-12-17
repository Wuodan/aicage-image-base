#!/usr/bin/env bash
set -euo pipefail

if [[ -f /etc/locale.gen ]]; then
  sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
fi

locale-gen
