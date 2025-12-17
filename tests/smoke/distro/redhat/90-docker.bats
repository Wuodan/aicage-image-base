#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers/os.bash"

setup_file() {
  require_fedora
}

@test "docker cli present" {
  run docker run --rm \
    "${AICAGE_IMAGE_BASE_IMAGE}" \
    /bin/bash -lc "set -euo pipefail
      docker --version
      docker buildx version"
  [ "$status" -eq 0 ]
}
