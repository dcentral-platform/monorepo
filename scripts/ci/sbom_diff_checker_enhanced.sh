#!/bin/bash
# Enhanced SBOM Diff Checker Script
# Compares two SBOM (Software Bill of Materials) files to identify license and security changes.
# This is a more comprehensive version that includes actual license compatibility checking.

set -e

# Configuration
OLD_SBOM=${1:-"edge_sbom_prev.spdx.json"}
NEW_SBOM=${2:-"edge-gateway_sbom.spdx.json"}
GPL_COMPATIBLE_FILE="scripts/ci/gpl_compatible_licenses.txt"
OUTPUT_DIR="sbom_diff_reports"
mkdir -p "$OUTPUT_DIR"

# Create GPL compatible licenses file if it doesn't exist
if [ ! -f "$GPL_COMPATIBLE_FILE" ]; then
  cat > "$GPL_COMPATIBLE_FILE" <<EOL
GPL-2.0
GPL-3.0
LGPL-2.0
LGPL-2.1
LGPL-3.0
AGPL-3.0
Apache-2.0
MIT
BSD-2-Clause
BSD-3-Clause
MPL-2.0
CC0-1.0
Unlicense
ISC
Artistic-2.0
Python-2.0
Zlib
EOL
fi

# Check if previous SBOM exists, if not, just validate the current one
if [ ! -f "$OLD_SBOM" ]; then
  echo "Previous SBOM not found at $OLD_SBOM."
  echo "This appears to be the first run. Checking current SBOM for GPL-incompatible licenses."
  
  # Create empty old SBOM
  echo '{"packages":[]}' > "$OLD_SBOM"
fi

echo "Comparing $OLD_SBOM with $NEW_SBOM"

# Extract licenses from SBOMs
if command -v jq &> /dev/null; then
  jq -r '.packages[]?.licenseConcluded // .packages[]?.licenseDeclared // ""' "$NEW_SBOM" | grep -v '^$' | sort -u > "$OUTPUT_DIR/new_licenses.txt"
  jq -r '.packages[]?.licenseConcluded // .packages[]?.licenseDeclared // ""' "$OLD_SBOM" | grep -v '^$' | sort -u > "$OUTPUT_DIR/old_licenses.txt"
else
  echo "Error: jq is required but not installed."
  exit 1
fi

# Find added licenses
comm -13 "$OUTPUT_DIR/old_licenses.txt" "$OUTPUT_DIR/new_licenses.txt" > "$OUTPUT_DIR/added_licenses.txt"

# Find removed licenses
comm -23 "$OUTPUT_DIR/old_licenses.txt" "$OUTPUT_DIR/new_licenses.txt" > "$OUTPUT_DIR/removed_licenses.txt"

# Check for GPL-incompatible licenses
incompatible_licenses=()
while IFS= read -r license; do
  # Skip license expressions with 'AND' and 'OR' for now (complex expressions)
  if [[ "$license" == *" AND "* || "$license" == *" OR "* ]]; then
    echo "Complex license expression found: $license - manual review recommended"
    continue
  fi
  
  # Check if the license is GPL compatible
  if ! grep -q "$license" "$GPL_COMPATIBLE_FILE"; then
    incompatible_licenses+=("$license")
  fi
done < "$OUTPUT_DIR/added_licenses.txt"

# Generate report
cat > "$OUTPUT_DIR/sbom_diff_report.md" <<EOL
# SBOM Diff Report

## Overview
- **Previous SBOM:** \`$(basename "$OLD_SBOM")\`
- **New SBOM:** \`$(basename "$NEW_SBOM")\`
- **Generated:** $(date)

## License Changes

### Added Licenses ($(wc -l < "$OUTPUT_DIR/added_licenses.txt" | tr -d ' '))
$(if [ -s "$OUTPUT_DIR/added_licenses.txt" ]; then
  cat "$OUTPUT_DIR/added_licenses.txt" | sed 's/^/- /'
else
  echo "- None"
fi)

### Removed Licenses ($(wc -l < "$OUTPUT_DIR/removed_licenses.txt" | tr -d ' '))
$(if [ -s "$OUTPUT_DIR/removed_licenses.txt" ]; then
  cat "$OUTPUT_DIR/removed_licenses.txt" | sed 's/^/- /'
else
  echo "- None"
fi)

### GPL-Incompatible Licenses Found (${#incompatible_licenses[@]})
$(if [ ${#incompatible_licenses[@]} -gt 0 ]; then
  printf -- "- %s\n" "${incompatible_licenses[@]}"
else
  echo "- None"
fi)

## Next Steps
$(if [ ${#incompatible_licenses[@]} -gt 0 ]; then
  echo "- **CRITICAL:** Review the GPL-incompatible licenses above and ensure they're properly handled"
  echo "- Consult with legal team before proceeding"
  echo "- Update the GPL compatibility list if any licenses have been cleared by legal"
else
  echo "- No incompatible licenses found - clear to proceed"
fi)
EOL

echo "Generated report: $OUTPUT_DIR/sbom_diff_report.md"

# Exit with error if incompatible licenses are found
if [ ${#incompatible_licenses[@]} -gt 0 ]; then
  echo "❌ Found ${#incompatible_licenses[@]} GPL-incompatible licenses"
  printf -- "  - %s\n" "${incompatible_licenses[@]}"
  echo "Please review the licenses and consult with legal team."
  exit 1
else
  echo "✅ No GPL-incompatible licenses found"
  exit 0
fi