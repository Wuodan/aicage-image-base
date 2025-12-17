#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers/os.bash"

setup_file() {
  require_fedora
}

@test "rust toolchain present" {
  run docker run --rm \
    "${AICAGE_IMAGE_BASE_IMAGE}" \
    /bin/bash -lc "set -euo pipefail
      command -v rustc
      command -v cargo
      command -v rustfmt
      command -v clippy-driver >/dev/null || command -v cargo-clippy >/dev/null"
  [ "$status" -eq 0 ]
}
