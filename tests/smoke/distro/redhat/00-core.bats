#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers/os.bash"

setup_file() {
  require_fedora
}

@test "core utilities present" {
  run docker run --rm \
    "${AICAGE_IMAGE_BASE_IMAGE}" \
    /bin/bash -lc "set -euo pipefail
      command -v gosu
      command -v dig
      command -v ip
      command -v rsync
      command -v tree
      command -v patch
      command -v file
      command -v less
      command -v 7z >/dev/null || command -v 7za >/dev/null"
  [ "$status" -eq 0 ]
}
