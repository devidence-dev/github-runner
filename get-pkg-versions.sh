#!/usr/bin/env bash
# Reads packages from packages.yml and queries their available versions
# from the same Debian image used in the Dockerfile.
# Output is ready to copy-paste into each apt-get install block.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="${SCRIPT_DIR}/packages.yml"
IMAGE="debian:13.6-slim"

if [ ! -f "$PACKAGES_FILE" ]; then
    echo "Error: packages.yml not found at ${PACKAGES_FILE}" >&2
    exit 1
fi

# Parse a section from packages.yml given a key (build or runtime)
parse_section() {
    local section="$1"
    python3 -c "
import sys
try:
    import yaml
    with open('${PACKAGES_FILE}') as f:
        data = yaml.safe_load(f)
    for pkg in data.get('${section}', []):
        print(pkg)
except ImportError:
    in_section = False
    with open('${PACKAGES_FILE}') as f:
        for line in f:
            stripped = line.strip()
            if stripped == '${section}:':
                in_section = True
                continue
            if in_section:
                if stripped.startswith('- '):
                    print(stripped[2:])
                elif stripped and not stripped.startswith('#'):
                    break
"
}

query_versions() {
    local section="$1"
    local packages packages_inline
    packages=$(parse_section "$section")

    if [ -z "$packages" ]; then
        echo "  (no packages in section '${section}')" >&2
        return
    fi

    packages_inline=$(echo "$packages" | tr '\n' ' ')

    docker run --rm "${IMAGE}" bash -c "
        apt-get update -qq 2>/dev/null
        for pkg in ${packages_inline}; do
            version=\$(apt-cache policy \"\$pkg\" 2>/dev/null | awk '/Candidate:/ {print \$2}')
            if [ -n \"\$version\" ] && [ \"\$version\" != '(none)' ]; then
                echo \"    \$pkg=\$version \\\\\"
            else
                echo \"    # \$pkg  <-- not found or no candidate\" >&2
            fi
        done
    "
}

echo "Fetching package versions from ${IMAGE}..."
echo "Source: ${PACKAGES_FILE}"
echo ""
echo "=== build stage ==="
query_versions "build"
echo ""
echo "=== runtime stage ==="
query_versions "runtime"
