#!/usr/bin/env bash
set -euo pipefail

image_ref="${1:?usage: verify-provenance.sh <image-ref>}"
image_repo="${image_ref%@*}"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

raw="$(docker buildx imagetools inspect --raw "${image_ref}")"
image_digest="$(printf '%s' "${raw}" | jq -r '.manifests[]?
  | select(.annotations."vnd.docker.reference.type"!="attestation-manifest")
  | .digest' | head -n1)"
if [ -z "${image_digest}" ]; then
  image_digest="$(docker buildx imagetools inspect "${image_ref}" \
    | sed -n 's/^Digest:[[:space:]]*//p' | head -n1)"
fi
test -n "${image_digest}"

att_digest="$(printf '%s' "${raw}" | jq -r '.manifests[]?
  | select(.annotations."vnd.docker.reference.type"=="attestation-manifest")
  | .digest' | head -n1)"
if [ -z "${att_digest}" ]; then
  att_digest="$(docker buildx imagetools inspect --raw "${image_repo}@${image_digest}" \
    | jq -r '.manifests[]?
      | select(.annotations."vnd.docker.reference.type"=="attestation-manifest")
      | .digest' | head -n1)"
fi
test -n "${att_digest}"

att_manifest="$(oras manifest fetch --output - "${image_repo}@${att_digest}")"
layer_digest="$(printf '%s' "${att_manifest}" | jq -r '.layers[]
  | select(.annotations."in-toto.io/predicate-type"
    | startswith("https://slsa.dev/provenance/"))
  | .digest' | head -n1)"
test -n "${layer_digest}"

att_path="${tmp_dir}/attestation.json"
decoded_path="${tmp_dir}/attestation.decoded.json"
oras blob fetch --output "${att_path}" "${image_repo}@${layer_digest}"

if [ "$(head -c2 "${att_path}" | od -An -tx1 | tr -d ' \n')" = "1f8b" ]; then
  gzip -dc "${att_path}" > "${decoded_path}"
else
  cp "${att_path}" "${decoded_path}"
fi

digest_no_prefix="${image_digest#sha256:}"
if jq -e 'has("payload")' "${decoded_path}" >/dev/null; then
  jq -r '.payload' "${decoded_path}" \
    | base64 -d \
    | jq -e --arg d "${digest_no_prefix}" '
      (.predicateType | startswith("https://slsa.dev/provenance/"))
      and
      (.subject[]? | select(.digest.sha256 == $d))
    ' >/dev/null
else
  jq -e --arg d "${digest_no_prefix}" '
    (.predicateType | startswith("https://slsa.dev/provenance/"))
    and
    (.subject[]? | select(.digest.sha256 == $d))
  ' "${decoded_path}" >/dev/null
fi
