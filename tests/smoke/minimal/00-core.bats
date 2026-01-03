#!/usr/bin/env bats

@test "core utilities present" {
  run docker run --rm \
    "${AICAGE_IMAGE_BASE_IMAGE}" \
    -c '
      set -euo pipefail
      command -v curl
      command -v git
      command -v tini
    '
  [ "$status" -eq 0 ]
}
