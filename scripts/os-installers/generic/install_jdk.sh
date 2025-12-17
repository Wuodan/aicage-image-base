#!/usr/bin/env bash
set -euo pipefail

if command -v java >/dev/null 2>&1; then
  exit 0
fi

: "${TARGETARCH:?TARGETARCH is required}"

case "${TARGETARCH}" in
  amd64) JDK_ARCH="x64" ;;
  arm64) JDK_ARCH="aarch64" ;;
  *)
    echo "Unsupported TARGETARCH ${TARGETARCH}" >&2
    exit 1
    ;;
esac

jdk_version="$(
  curl -fsSL https://api.adoptium.net/v3/info/available_releases \
    | jq -r '.most_recent_feature_release'
)"

if [[ -z "${jdk_version}" || "${jdk_version}" == "null" ]]; then
  echo "Unable to resolve latest JDK version" >&2
  exit 1
fi

jdk_json="$(
  curl -fsSL \
    "https://api.adoptium.net/v3/assets/feature_releases/${jdk_version}/ga?architecture=${JDK_ARCH}&heap_size=normal&image_type=jdk&jvm_impl=hotspot&os=linux&vendor=eclipse"
)"

jdk_url="$(echo "${jdk_json}" | jq -r '.[0].binary.package.link')"
jdk_checksum="$(echo "${jdk_json}" | jq -r '.[0].binary.package.checksum')"

if [[ -z "${jdk_url}" || "${jdk_url}" == "null" ]]; then
  echo "Unable to resolve JDK download URL" >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

archive_path="${tmp_dir}/jdk.tar.gz"
curl -fsSL "${jdk_url}" -o "${archive_path}"

if [[ -n "${jdk_checksum}" && "${jdk_checksum}" != "null" ]]; then
  echo "${jdk_checksum}  ${archive_path}" | sha256sum -c -
fi

install_root="/opt/java"
mkdir -p "${install_root}"
tar -xzf "${archive_path}" -C "${install_root}"

jdk_dir="$(tar -tzf "${archive_path}" | head -1 | cut -d/ -f1)"
jdk_home="${install_root}/${jdk_dir}"

if [[ ! -d "${jdk_home}" ]]; then
  echo "JDK install directory not found: ${jdk_home}" >&2
  exit 1
fi

ln -sfn "${jdk_home}" "${install_root}/latest"

for bin in "${install_root}/latest/bin/"*; do
  ln -sf "${bin}" "/usr/local/bin/$(basename "${bin}")"
done

cat > /etc/profile.d/java.sh <<'JAVA'
export JAVA_HOME=/opt/java/latest
export PATH="$JAVA_HOME/bin:$PATH"
JAVA
