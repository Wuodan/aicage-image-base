# Task 05: Validate license compliance for tools bundled in our developer Docker images

## Goal
Produce a *practical* compliance report for what we redistribute in the Docker image(s), focusing on:
- What comes from the **base distro package manager** (Debian/Ubuntu `apt`, Fedora/RHEL `dnf`)
- What is installed **outside** the package manager (curl/wget installers, GitHub releases, npm/pipx, etc.)
- Whether our build steps accidentally remove required **license texts/notices**
- A lightweight set of artifacts we can ship in the repo or image to be “sane by default”

This is not a legal opinion. The goal is “industry-standard hygiene” for redistribution.

---

## Scope
- Identify and classify **everything we install**
- Ensure license texts for distro packages remain available inside the final image
- For non-distro installs, record **source + license** and preserve upstream LICENSE/NOTICE if practical
- Flag **high-attention** licenses (e.g., AGPL/SSPL/Elastic/Commercial EULA) for manual decision

---

## Step 1 — Inventory what gets installed (per Dockerfile / build scripts)

### 1A) Parse Dockerfile(s) + install scripts to find installers
Search for common patterns that indicate non-distro installs:

```bash
rg -n --hidden --no-ignore-vcs \
  -e 'curl\s+.*\|\s*(sh|bash)' \
  -e 'wget\s+.*\|\s*(sh|bash)' \
  -e 'pipx\s+install' \
  -e 'pip\s+install' \
  -e 'npm\s+(-g\s+)?install' \
  -e 'corepack\s+enable' \
  -e 'go\s+install\s+[^ ]+@' \
  -e 'cargo\s+install' \
  -e 'git\s+clone' \
  -e 'ADD\s+https?://' \
  -e 'COPY\s+--from=' \
  Dockerfile* **/*.sh **/*.bash **/*.ps1 || true
```

Write down a list of “non-distro installs” with:
- tool name
- install method (curl|sh, GitHub release tarball, npm, pipx, etc.)
- upstream project URL

### 1B) Extract package-manager installs
Find apt/dnf package lists from Dockerfile/build scripts:

```bash
rg -n --hidden --no-ignore-vcs \
  -e 'apt-get\s+install' \
  -e 'apt\s+install' \
  -e 'dnf\s+install' \
  -e 'microdnf\s+install' \
  Dockerfile* **/*.sh **/*.bash || true
```

Capture the final resolved package list per image (see Step 2).

---

## Step 2 — Build the image and collect an “as-shipped” package inventory

> Do this per built image tag you plan to publish.

### Debian/Ubuntu (dpkg/apt)
Inside the built image:

```bash
dpkg-query -W -f='${Package}\t${Version}\n' | sort > /tmp/packages.tsv
```

### Fedora/RHEL (rpm/dnf)
Inside the built image:

```bash
rpm -qa --qf '%{NAME}\t%{VERSION}-%{RELEASE}\t%{LICENSE}\n' | sort > /tmp/packages.tsv
```

Copy `/tmp/packages.tsv` out as a build artifact (or print it in CI logs).

---

## Step 3 — Validate “license texts are kept” for distro-installed packages

### 3A) Check we did not delete license directories
Scan Dockerfile(s) for risky cleanup:

- BAD (can break compliance):
  - `rm -rf /usr/share/doc/*`
  - `rm -rf /usr/share/licenses/*`
  - `rm -rf /usr/share/man/*` (less serious, but can remove docs)

- OK:
  - `rm -rf /var/lib/apt/lists/*`
  - `apt-get clean`
  - `dnf clean all`

Search:

```bash
rg -n --hidden --no-ignore-vcs \
  -e 'rm\s+-rf\s+/usr/share/(doc|licenses)' \
  -e 'rm\s+-rf\s+/usr/share/man' \
  -e 'strip\s+' \
  Dockerfile* **/*.sh **/*.bash || true
```

If you find removal of `/usr/share/doc` or `/usr/share/licenses`, propose a safer alternative:
- Keep `/usr/share/licenses` intact
- Keep `/usr/share/doc` intact, or only remove *specific* large docs you can justify (prefer not)

### 3B) Spot-check license presence in the final image
Run in the final image:

```bash
test -d /usr/share/licenses && echo "OK: /usr/share/licenses exists" || echo "WARN: missing /usr/share/licenses"
test -d /usr/share/doc && echo "OK: /usr/share/doc exists" || echo "WARN: missing /usr/share/doc"
```

---

## Step 4 — Handle “non-distro installs” (the real compliance risk)

For each tool installed outside apt/dnf/rpm repos:

### 4A) Record provenance + license
For each tool, create an entry with:
- Name + version
- Upstream project URL
- Install method
- License type (from upstream)
- Where we place LICENSE/NOTICE text (if any)

Minimum acceptable output: a repo file like `THIRD_PARTY_NOTICES.md` with a small table.

### 4B) Preserve LICENSE/NOTICE when practical
Preferred patterns:
- If you download a tarball that contains LICENSE/NOTICE: copy it into
  - `/usr/share/licenses/<tool>/` or `/opt/licenses/<tool>/`
- If installing via npm/pipx: capture license from upstream repo and include it in the notices file
- If using a curl|sh bootstrap: identify the real upstream repo and store the license text or a link + version

### 4C) Flag “high-attention” licenses
If any non-distro tool is under:
- AGPL
- SSPL
- Elastic License v2
- commercial EULA / “no redistribution”
…then flag it as **NEEDS DECISION** and do not ship it by default unless approved.

---

## Step 5 — Generate an SBOM (recommended) and extract license hints
Generate an SBOM for the image in CI and keep it as an artifact.

If `syft` is available:

```bash
syft <image-tag> -o spdx-json > sbom.spdx.json
# or CycloneDX:
syft <image-tag> -o cyclonedx-json > sbom.cdx.json
```

Then:
- Use the SBOM to cross-check that your “non-distro installs” list isn’t missing anything.
- Use the SBOM license fields as *hints* (they are not always perfect).

---

## Step 6 — Produce the final report (deliverable)

Create `COMPLIANCE.md` (or update it) containing:

1. **Summary**
   - Base image(s)
   - Distro package manager used
   - Statement: “Distro packages retain their license texts under /usr/share/doc and/or /usr/share/licenses”

2. **Package-manager inventory**
   - Attach or link to `packages.tsv` per image build

3. **Non-distro installs**
   - Table: tool | version | source | license | where notice/license is included | notes

4. **Flags / decisions**
   - Any tool with restrictive license or unclear redistribution terms

5. **CI checks**
   - “Fail build if Dockerfile removes /usr/share/licenses or /usr/share/doc”
   - “Fail build if a new non-distro install is added without an entry in THIRD_PARTY_NOTICES.md”

---

## Optional CI guardrails (simple + effective)

### A) Fail if we delete license directories
Add a CI step that scans the repo:

```bash
if rg -n -e 'rm\s+-rf\s+/usr/share/(doc|licenses)' Dockerfile* **/*.sh **/*.bash; then
  echo "ERROR: build removes /usr/share/doc or /usr/share/licenses"
  exit 1
fi
```

### B) Fail if “curl|sh” is introduced without a notice entry
Require a marker line near each non-distro install, e.g.:

```bash
# THIRD_PARTY: <tool> <version> <license> <source-url>
```

CI can then enforce that each `THIRD_PARTY:` marker exists in `THIRD_PARTY_NOTICES.md`.

---

## Definition of Done
- [ ] `packages.tsv` produced per image build
- [ ] `THIRD_PARTY_NOTICES.md` exists and covers all non-distro installs
- [ ] Final image keeps `/usr/share/licenses` (and ideally `/usr/share/doc`)
- [ ] SBOM artifact generated (preferred)
- [ ] CI guardrails added (at least the “don’t delete licenses” check)
