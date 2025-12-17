require_fedora() {
  run docker run --rm \
    "${AICAGE_IMAGE_BASE_IMAGE}" \
    /bin/bash -lc "source /etc/os-release && echo ${ID}"
  [ "$status" -eq 0 ]
  if [[ "${output}" != "fedora" ]]; then
    skip "Fedora-only test"
  fi
}
