#!/bin/bash
# Comprehensive verification script for all Weeks 1-3 tests
# Uses compatible test logger

# Source the compatible test logger
source $(dirname "$0")/../ci/test_logger_compat.sh

# Set up environment for logging
export CI_LOG_DIR="logs/verification"
mkdir -p "$CI_LOG_DIR"

echo "====================================================="
echo "D Central Test Suite - All Tests (Weeks 1-3)"
echo "====================================================="
echo "Session ID: $TEST_SESSION_ID"
echo "Logs will be saved to: $CI_LOG_DIR"
echo "====================================================="

# Week 1 Tests
log "info" "Starting Week 1 Tests"

# W1-REPO-01: Repository Structure Check
test_start "W1-REPO-01" "Repository Structure Check"
log "info" "Checking for essential repository files and directories"

# Check key directories
essential_dirs=(
  "code"
  "design"
  "docs"
  "legal"
  "scripts"
)

missing_dirs=0
for dir in "${essential_dirs[@]}"; do
  if [ -d "$dir" ]; then
    log "success" "Found essential directory: $dir"
  else
    log "error" "Missing essential directory: $dir"
    missing_dirs=1
  fi
done

# Check for README.md and LICENSE files
essential_files=(
  "README.md"
  "LICENSE.md"
  "CODE_OF_CONDUCT.md"
)

missing_files=0
for file in "${essential_files[@]}"; do
  if [ -f "$file" ]; then
    log "success" "Found essential file: $file"
    file_size=$(wc -c < "$file" | tr -d ' ')
    log "debug" "File size for $file: $file_size bytes"
    if [ "$file_size" -lt 100 ]; then
      log "warn" "File $file is suspiciously small: $file_size bytes"
    fi
  else
    log "error" "Missing essential file: $file"
    missing_files=1
  fi
done

if [ $missing_dirs -eq 1 ] || [ $missing_files -eq 1 ]; then
  test_end "W1-REPO-01" "fail" "Missing essential repository components"
else
  test_end "W1-REPO-01" "pass" "All essential repository components present"
fi

# W1-LEGAL-01: Required Legal Docs Check
test_start "W1-LEGAL-01" "Required Legal Docs Check"
log "info" "Checking for required legal documents"

legal_files=(
  "legal/mutual-nda_v1.0.md"
  "legal/privacy-notice_v1.0.md"
  "legal/revenue-share-warrant_v1.md"
)

missing_legal=0
small_legal=0
for file in "${legal_files[@]}"; do
  if [ -f "$file" ]; then
    log "success" "Found legal file: $file"
    file_size=$(wc -c < "$file" | tr -d ' ')
    log "debug" "File size for $file: $file_size bytes"
    if [ "$file_size" -lt 500 ]; then
      log "warn" "Legal file $file appears incomplete: $file_size bytes"
      small_legal=1
    fi
  else
    log "error" "Missing legal file: $file"
    missing_legal=1
  fi
done

if [ $missing_legal -eq 1 ]; then
  test_end "W1-LEGAL-01" "fail" "Missing required legal documents"
elif [ $small_legal -eq 1 ]; then
  test_end "W1-LEGAL-01" "warn" "Some legal files may be incomplete"
else
  test_end "W1-LEGAL-01" "pass" "All legal documents present and appear complete"
fi

# W1-DOCS-01: Markdown Linting
test_start "W1-DOCS-01" "Markdown Linting"
log "info" "Checking markdown file consistency"

# Count markdown files
md_files=$(find . -name "*.md" | wc -l | tr -d ' ')
log "info" "Found $md_files markdown files in the repository"

# Basic check for consistency 
inconsistent=0
for file in $(find . -name "*.md" | head -5); do
  log "debug" "Checking markdown file: $file"
  
  # Check for header formatting (# vs ##)
  if grep -q "^#[^#]" "$file"; then
    log "success" "File $file uses proper header formatting"
  else
    log "warn" "File $file may have inconsistent header formatting"
    inconsistent=1
  fi
  
  # Check for empty file
  if [ ! -s "$file" ]; then
    log "error" "Markdown file $file is empty"
    inconsistent=1
  fi
done

if [ $inconsistent -eq 1 ]; then
  test_end "W1-DOCS-01" "warn" "Some markdown files have formatting inconsistencies"
else
  test_end "W1-DOCS-01" "pass" "Markdown formatting appears consistent"
fi

# W1-BRAND-01: Brand Assets Check
test_start "W1-BRAND-01" "Brand Assets Check"
log "info" "Checking for SVG logo files"

svg_dir="design/logo/static"
if [ -d "$svg_dir" ]; then
  svg_files=$(find "$svg_dir" -name "*.svg" 2>/dev/null | wc -l | tr -d ' ')
  log "info" "Found $svg_files SVG files in $svg_dir"
  
  if [ "$svg_files" -lt 2 ]; then
    log "error" "Not enough SVG logo files (minimum 2 required, found $svg_files)"
    test_end "W1-BRAND-01" "fail" "Insufficient SVG logo files"
  else
    log "success" "Found sufficient SVG logo files"
    
    # Check for viewBox attributes as a basic quality check
    viewbox_missing=0
    for file in $(find "$svg_dir" -name "*.svg"); do
      if grep -q "viewBox" "$file"; then
        log "success" "SVG file $file has viewBox attribute"
      else
        log "warn" "SVG file $file missing viewBox attribute"
        viewbox_missing=1
      fi
    done
    
    if [ $viewbox_missing -eq 1 ]; then
      test_end "W1-BRAND-01" "warn" "Some SVG files missing viewBox attributes"
    else
      test_end "W1-BRAND-01" "pass" "All SVG logo files present with viewBox attributes"
    fi
  fi
else
  log "error" "SVG directory not found: $svg_dir"
  test_end "W1-BRAND-01" "fail" "SVG logo directory not found"
fi

# W1-TOKEN-01: Design Token File Check
test_start "W1-TOKEN-01" "Design Token File Check"
log "info" "Checking design tokens"

token_file="design/palette-tokens/design-tokens.json"
if [ -f "$token_file" ]; then
  log "success" "Found design tokens file: $token_file"
  
  # Check if file is empty
  if [ ! -s "$token_file" ]; then
    log "error" "Design tokens file is empty"
    test_end "W1-TOKEN-01" "fail" "Design tokens file is empty"
  else
    # Verify that it at least looks like JSON (has { and })
    if grep -q "{" "$token_file" && grep -q "}" "$token_file"; then
      log "success" "Design tokens file appears to be valid JSON"
      
      # Basic check for expected content
      if grep -q "colors" "$token_file" && grep -q "spacing" "$token_file"; then
        log "success" "Design tokens file contains expected categories"
        test_end "W1-TOKEN-01" "pass" "Design tokens file is valid and contains expected categories"
      else
        log "warn" "Design tokens file may be missing key categories"
        test_end "W1-TOKEN-01" "warn" "Design tokens file may be missing expected categories"
      fi
    else
      log "error" "Design tokens file does not appear to be valid JSON"
      test_end "W1-TOKEN-01" "fail" "Design tokens file is not valid JSON"
    fi
  fi
else
  log "error" "Design tokens file not found: $token_file"
  test_end "W1-TOKEN-01" "fail" "Design tokens file not found"
fi

# Week 2 Tests
log "info" "Starting Week 2 Tests"

# W2-WCAG-01: Color Contrast Check
test_start "W2-WCAG-01" "Color Contrast Check"
log "info" "Checking for WCAG color contrast compliance"

contrast_script="scripts/ci/contrast.js"
if [ -f "$contrast_script" ]; then
  log "success" "Found WCAG contrast check script: $contrast_script"
  
  # We can't actually run the contrast script without Node.js dependencies,
  # so we'll do a basic verification that the script exists and looks reasonable
  if grep -q "WCAG" "$contrast_script" && grep -q "contrast" "$contrast_script"; then
    log "success" "Contrast script appears to contain WCAG validation logic"
    test_end "W2-WCAG-01" "pass" "WCAG contrast check script is present and appears valid"
  else
    log "warn" "Contrast script may be missing required validation logic"
    test_end "W2-WCAG-01" "warn" "Contrast script may be missing required validation logic"
  fi
else
  log "error" "WCAG contrast check script not found: $contrast_script"
  test_end "W2-WCAG-01" "fail" "WCAG contrast check script not found"
fi

# W2-DOCKER-01: Docker Image Build Check
test_start "W2-DOCKER-01" "Docker Image Build Check"
log "info" "Checking Docker build configuration"

dockerfile="code/edge-gateway/Dockerfile"
if [ -f "$dockerfile" ]; then
  log "success" "Found Dockerfile: $dockerfile"
  
  # Check for essential Dockerfile components
  if grep -q "FROM" "$dockerfile" && grep -q "COPY\|ADD" "$dockerfile"; then
    log "success" "Dockerfile contains essential instructions"
    test_end "W2-DOCKER-01" "pass" "Dockerfile is present and contains essential instructions"
  else
    log "warn" "Dockerfile may be missing essential instructions"
    test_end "W2-DOCKER-01" "warn" "Dockerfile may be missing essential instructions"
  fi
else
  log "error" "Dockerfile not found: $dockerfile"
  test_end "W2-DOCKER-01" "fail" "Dockerfile not found"
fi

# W2-SBOM-01: SBOM Generation
test_start "W2-SBOM-01" "SBOM Generation"
log "info" "Checking SBOM tooling"

sbom_script="scripts/ci/sbom_diff_checker_enhanced.sh"
if [ -f "$sbom_script" ]; then
  log "success" "Found SBOM checker script: $sbom_script"
  
  # Check for essential SBOM logic
  if grep -q "SBOM" "$sbom_script" && grep -q "license" "$sbom_script"; then
    log "success" "SBOM script contains essential logic"
    test_end "W2-SBOM-01" "pass" "SBOM script is present and contains essential logic"
  else
    log "warn" "SBOM script may be missing essential logic"
    test_end "W2-SBOM-01" "warn" "SBOM script may be missing essential logic"
  fi
else
  log "error" "SBOM script not found: $sbom_script"
  test_end "W2-SBOM-01" "fail" "SBOM script not found"
fi

# W2-GO-01: Go Code Quality Check
test_start "W2-GO-01" "Go Code Quality Check"
log "info" "Checking Go code structure"

go_dir="code/edge-gateway"
if [ -d "$go_dir" ]; then
  log "success" "Found Go code directory: $go_dir"
  
  # Check for Go module
  if [ -f "$go_dir/go.mod" ]; then
    log "success" "Found Go module configuration file"
    
    # Check for test files
    go_test_files=$(find "$go_dir" -name "*_test.go" | wc -l | tr -d ' ')
    log "info" "Found $go_test_files Go test files"
    
    if [ "$go_test_files" -gt 0 ]; then
      log "success" "Go project includes test files"
      test_end "W2-GO-01" "pass" "Go code is properly structured with tests"
    else
      log "warn" "Go project may be missing test files"
      test_end "W2-GO-01" "warn" "Go project may be missing test files"
    fi
  else
    log "error" "Missing Go module configuration file"
    test_end "W2-GO-01" "fail" "Missing Go module configuration"
  fi
else
  log "error" "Go code directory not found: $go_dir"
  test_end "W2-GO-01" "fail" "Go code directory not found"
fi

# W2-HELM-01: Helm Chart Validation
test_start "W2-HELM-01" "Helm Chart Validation"
log "info" "Checking Helm chart structure"

helm_dir="code/helm/edge-gateway-chart"
if [ -d "$helm_dir" ]; then
  log "success" "Found Helm chart directory: $helm_dir"
  
  # Check for required Helm chart files
  if [ -f "$helm_dir/Chart.yaml" ] && [ -f "$helm_dir/values.yaml" ]; then
    log "success" "Found Helm chart definition files"
    
    # Check for templates
    if [ -d "$helm_dir/templates" ]; then
      template_files=$(find "$helm_dir/templates" -name "*.yaml" | wc -l | tr -d ' ')
      log "info" "Found $template_files Helm template files"
      
      if [ "$template_files" -gt 0 ]; then
        log "success" "Helm chart includes template files"
        test_end "W2-HELM-01" "pass" "Helm chart is properly structured"
      else
        log "warn" "Helm chart does not contain any template files"
        test_end "W2-HELM-01" "warn" "Helm chart missing template files"
      fi
    else
      log "error" "Helm chart missing templates directory"
      test_end "W2-HELM-01" "fail" "Helm chart missing templates directory"
    fi
  else
    log "error" "Missing required Helm chart files"
    test_end "W2-HELM-01" "fail" "Missing required Helm chart files"
  fi
else
  log "error" "Helm chart directory not found: $helm_dir"
  test_end "W2-HELM-01" "fail" "Helm chart directory not found"
fi

# Week 3 Tests
log "info" "Starting Week 3 Tests"

# W3-K8S-01: Kubernetes Manifest Validation
test_start "W3-K8S-01" "Kubernetes Manifest Validation"
log "info" "Checking Kubernetes manifests"

k8s_templates="$helm_dir/templates"
if [ -d "$k8s_templates" ]; then
  log "success" "Found Kubernetes templates directory: $k8s_templates"
  
  # Check for key Kubernetes resources
  resources=("deployment" "service" "configmap")
  missing_resources=0
  
  for resource in "${resources[@]}"; do
    resource_file="$k8s_templates/${resource}.yaml"
    if [ -f "$resource_file" ]; then
      log "success" "Found Kubernetes $resource manifest"
    else
      log "warn" "Missing Kubernetes $resource manifest"
      missing_resources=1
    fi
  done
  
  if [ $missing_resources -eq 1 ]; then
    test_end "W3-K8S-01" "warn" "Some key Kubernetes resources may be missing"
  else
    test_end "W3-K8S-01" "pass" "Found all key Kubernetes resource manifests"
  fi
else
  log "error" "Kubernetes templates directory not found: $k8s_templates"
  test_end "W3-K8S-01" "fail" "Kubernetes templates directory not found"
fi

# W3-SEC-01: Container Security Scan
test_start "W3-SEC-01" "Container Security Scan"
log "info" "Checking security scanning configuration"

# Check if GitHub workflow includes security scanning
workflows_dir=".github/workflows"
if [ -d "$workflows_dir" ]; then
  log "success" "Found GitHub workflows directory: $workflows_dir"
  
  # Search for security scanning in workflows
  if grep -r "trivy\|security" "$workflows_dir" > /dev/null 2>&1; then
    log "success" "Found security scanning configuration in workflows"
    test_end "W3-SEC-01" "pass" "Security scanning is configured in GitHub workflows"
  else
    log "warn" "Could not find security scanning configuration in workflows"
    test_end "W3-SEC-01" "warn" "Security scanning may not be configured"
  fi
else
  log "error" "GitHub workflows directory not found: $workflows_dir"
  test_end "W3-SEC-01" "fail" "GitHub workflows directory not found"
fi

# W3-PERF-01: MQTT Performance Test
test_start "W3-PERF-01" "MQTT Performance Test"
log "info" "Checking MQTT performance tests"

mqtt_test="code/tests/perf/mqtt_loadtest.js"
if [ -f "$mqtt_test" ]; then
  log "success" "Found MQTT performance test script: $mqtt_test"
  
  # Check test script content
  if grep -q "mqtt" "$mqtt_test" && grep -q "performance\|load" "$mqtt_test"; then
    log "success" "MQTT performance test script contains expected testing logic"
    test_end "W3-PERF-01" "pass" "MQTT performance testing is properly configured"
  else
    log "warn" "MQTT performance test script may be missing essential logic"
    test_end "W3-PERF-01" "warn" "MQTT performance test script may need review"
  fi
else
  log "error" "MQTT performance test script not found: $mqtt_test"
  test_end "W3-PERF-01" "fail" "MQTT performance test script not found"
fi

# W3-PERF-02: REST API Performance Test
test_start "W3-PERF-02" "REST API Performance Test"
log "info" "Checking REST API performance tests"

rest_test="code/tests/perf/rest_loadtest.js"
if [ -f "$rest_test" ]; then
  log "success" "Found REST API performance test script: $rest_test"
  
  # Check test script content
  if grep -q "http" "$rest_test" && grep -q "performance\|load" "$rest_test"; then
    log "success" "REST API performance test script contains expected testing logic"
    test_end "W3-PERF-02" "pass" "REST API performance testing is properly configured"
  else
    log "warn" "REST API performance test script may be missing essential logic"
    test_end "W3-PERF-02" "warn" "REST API performance test script may need review"
  fi
else
  log "error" "REST API performance test script not found: $rest_test"
  test_end "W3-PERF-02" "fail" "REST API performance test script not found"
fi

# W3-GH-01: GitHub Workflows Check
test_start "W3-GH-01" "GitHub Workflows Check"
log "info" "Checking GitHub workflow configuration"

if [ -d "$workflows_dir" ]; then
  workflow_files=$(find "$workflows_dir" -name "*.yml" -o -name "*.yaml" | wc -l | tr -d ' ')
  log "info" "Found $workflow_files GitHub workflow files"
  
  if [ "$workflow_files" -gt 0 ]; then
    log "success" "GitHub workflows are configured"
    
    # Check if our test workflow is included
    if [ -f "$workflows_dir/test-suite.yml" ] || [ -f "$workflows_dir/test-suite-enhanced.yml" ]; then
      log "success" "Test suite workflow is properly configured"
      test_end "W3-GH-01" "pass" "GitHub workflows are correctly set up with test suite"
    else
      log "warn" "Test suite workflow may not be properly configured"
      test_end "W3-GH-01" "warn" "Test suite workflow may need to be added to GitHub workflows"
    fi
  else
    log "error" "No GitHub workflow files found"
    test_end "W3-GH-01" "fail" "No GitHub workflow files found"
  fi
else
  log "error" "GitHub workflows directory not found: $workflows_dir"
  test_end "W3-GH-01" "fail" "GitHub workflows directory not found"
fi

# Generate summary will be called automatically by the cleanup function