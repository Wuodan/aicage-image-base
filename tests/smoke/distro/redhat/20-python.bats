#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers/os.bash"

setup_file() {
  require_fedora
}

@test "python toolchain present" {
  run docker run --rm \
    "${AICAGE_IMAGE_BASE_IMAGE}" \
    /bin/bash -lc "set -euo pipefail
      command -v python3
      command -v pipx
      command -v python3-config"
  [ "$status" -eq 0 ]
}
