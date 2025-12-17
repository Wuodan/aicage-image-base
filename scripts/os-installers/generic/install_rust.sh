#!/usr/bin/env bash
set -euo pipefail

if command -v rustc >/dev/null 2>&1; then
  exit 0
fi

export RUSTUP_HOME=/usr/local/rustup
export CARGO_HOME=/usr/local/cargo

curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal --no-modify-path

PATH="${CARGO_HOME}/bin:${PATH}" rustup component add rustfmt clippy

for bin in "${CARGO_HOME}/bin/"*; do
  ln -sf "${bin}" "/usr/local/bin/$(basename "${bin}")"
done

cat > /etc/profile.d/rust.sh <<'RUST'
export RUSTUP_HOME=/usr/local/rustup
export CARGO_HOME=/usr/local/cargo
export PATH="$CARGO_HOME/bin:$PATH"
RUST
