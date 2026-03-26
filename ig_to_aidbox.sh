#!/usr/bin/env bash

set -euo pipefail

# Usage example:
# ./ig_to_aidbox.sh 0.4.0-46fb6c.tgz

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <ig_archive.tgz>"
  exit 1
fi

IGS_DIR="lib/smart_health_checks_test_kit/igs"
ARCHIVE_NAME="$1"
IG_ARCHIVE="$IGS_DIR/$ARCHIVE_NAME"

if [[ ! -f "$IG_ARCHIVE" ]]; then
  echo "Archive not found: $IG_ARCHIVE"
  exit 1
fi

if [[ "$ARCHIVE_NAME" == *.tgz ]]; then
  BASE_NAME="${ARCHIVE_NAME%.tgz}"
else
  echo "Unsupported archive format: $IG_ARCHIVE (expected .tgz)"
  exit 1
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

# 1. Unpack the .tgz archive in a temporary workspace
tar -xzf "$IG_ARCHIVE" -C "$WORK_DIR"

# 2. Locate the extracted IG directory (must contain package.json)
IG_DIR=""
if [[ -f "$WORK_DIR/package.json" ]]; then
  IG_DIR="$WORK_DIR"
else
  for d in "$WORK_DIR"/*; do
    if [[ -d "$d" && -f "$d/package.json" ]]; then
      IG_DIR="$d"
      break
    fi
  done
fi

if [[ -z "$IG_DIR" ]]; then
  echo "Could not find package.json in extracted archive."
  exit 1
fi

# 3. Update dependencies.hl7.fhir.uv.sdc from "current" to "latest"
python3 - "$IG_DIR/package.json" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    package_json = json.load(f)

deps = package_json.setdefault("dependencies", {})
if deps.get("hl7.fhir.uv.sdc") == "current":
    deps["hl7.fhir.uv.sdc"] = "latest"

with open(path, "w", encoding="utf-8") as f:
    json.dump(package_json, f, indent=2)
    f.write("\n")
PY

# 4. Repack to .tgz with aidbox suffix
OUTPUT_ARCHIVE="$IGS_DIR/${BASE_NAME}_aidbox.tgz"
if [[ "$IG_DIR" == "$WORK_DIR" ]]; then
  tar -czf "$OUTPUT_ARCHIVE" -C "$WORK_DIR" .
else
  tar -czf "$OUTPUT_ARCHIVE" -C "$WORK_DIR" "$(basename "$IG_DIR")"
fi

echo "Created: $OUTPUT_ARCHIVE"
