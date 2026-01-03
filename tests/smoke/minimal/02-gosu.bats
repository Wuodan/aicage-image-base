#!/usr/bin/env bats

@test "gosu present" {
  run docker run --rm \
    "${AICAGE_IMAGE_BASE_IMAGE}" \
    -c '
      set -euo pipefail
      command -v gosu
    '
  [ "$status" -eq 0 ]
}
