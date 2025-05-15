#!/bin/bash
# Demo verification script - runs a few key tests to demonstrate the logging framework

# Source the compatible test logger
source $(dirname "$0")/../ci/test_logger_compat.sh

# Set up environment for logging
export CI_LOG_DIR="logs/verification"
mkdir -p "$CI_LOG_DIR"

echo "====================================================="
echo "D Central Test Demo"
echo "====================================================="
echo "Session ID: $TEST_SESSION_ID"
echo "Logs will be saved to: $CI_LOG_DIR"
echo "====================================================="

# W1-REPO-01: Repository Structure Check - Intentionally pass
test_start "W1-REPO-01" "Repository Structure Check"
log "info" "Validating directory structure"
log "success" "Found expected directories"
test_end "W1-REPO-01" "pass" "All directory checks passed"

# W1-LEGAL-01: Required Legal Docs Check - Intentionally pass with warnings
test_start "W1-LEGAL-01" "Required Legal Docs Check"
log "info" "Checking for required legal documents"
log "success" "Found LICENSE.md"
log "success" "Found CODE_OF_CONDUCT.md"
log "warn" "Some files are smaller than expected"
test_end "W1-LEGAL-01" "warn" "Some legal files need review"

# W1-BRAND-01: Brand Assets Check - Intentionally fail
test_start "W1-BRAND-01" "Brand Assets Check"
log "info" "Checking for SVG logo files"
log "success" "Found SVG logo files"
log "error" "Logo files missing required metadata"
log_data "Missing metadata" "title: 4 files\ndescription: 3 files"
test_end "W1-BRAND-01" "fail" "Logo files are missing required metadata"

# W2-WCAG-01: Color Contrast Check - Intentionally pass
test_start "W2-WCAG-01" "Color Contrast Check"
log "info" "Running WCAG contrast check on design tokens"
log "success" "All colors pass WCAG 2.1 AA contrast requirements"
test_end "W2-WCAG-01" "pass" "All colors pass WCAG 2.1 AA contrast requirements"

# W3-PERF-01: MQTT Performance Test - Intentionally skip
test_start "W3-PERF-01" "MQTT Performance Test"
log "info" "Performance testing environment not available"
test_end "W3-PERF-01" "skip" "Performance testing environment not available"

# Generate summary will be called automatically by the cleanup function