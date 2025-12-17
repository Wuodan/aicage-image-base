#!/usr/bin/env bash
set -euo pipefail

dnf -y makecache

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
install_dir="${script_dir}/install"

mapfile -t install_scripts < <(find "${install_dir}" -maxdepth 1 -type f -name "*.sh" | sort)
for install_script in "${install_scripts[@]}"; do
  bash "${install_script}"
done

dnf clean all
