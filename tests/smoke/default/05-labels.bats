#!/usr/bin/env bats

setup() {
  ROOT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../../.." && pwd)"
  # shellcheck source=../../../scripts/common.sh
  source "${ROOT_DIR}/scripts/common.sh"
  load_config_file
  EXPECTED_DISTRO="$(get_base_field "${BASE_ALIAS}" base_image_distro)"
  EXPECTED_DESCRIPTION="$(get_base_field "${BASE_ALIAS}" base_image_description)"
}

@test "image labels include base metadata" {
  run docker image inspect \
    --format '{{ index .Config.Labels "org.aicage.base.distro" }}' \
    "${AICAGE_IMAGE_BASE_IMAGE}"
  [ "$status" -eq 0 ]
  [ "$output" = "${EXPECTED_DISTRO}" ]

  run docker image inspect \
    --format '{{ index .Config.Labels "org.aicage.base.description" }}' \
    "${AICAGE_IMAGE_BASE_IMAGE}"
  [ "$status" -eq 0 ]
  [ "$output" = "${EXPECTED_DESCRIPTION}" ]
}
