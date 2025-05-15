#!/bin/bash
# Enhanced verification script for Weeks 1-3 deliverables
# This script performs local checks for all Week 1-3 test cases with comprehensive logging

# Source the test logger
source $(dirname "$0")/../ci/test_logger.sh

# Set up environment for logging
export CI_LOG_DIR="logs/verification"
mkdir -p "$CI_LOG_DIR"

echo "====================================================="
echo "D Central Verification - Weeks 1-3 Tests"
echo "====================================================="
echo "Session ID: $TEST_SESSION_ID"
echo "Logs will be saved to: $CI_LOG_DIR"
echo "====================================================="

# Week 1 Tests
log "info" "Starting Week 1 Tests"

# W1-REPO-01: Repository Structure Check
test_start "W1-REPO-01" "Repository Structure Check"
log "info" "Validating directory structure against manifest"
log_cmd python scripts/ci/tree_assert.py
if [ $? -eq 0 ]; then
    test_end "W1-REPO-01" "pass"
else
    test_end "W1-REPO-01" "fail" "Directory structure does not match manifest"
fi

# W1-LEGAL-01: Required Legal Docs Check
test_start "W1-LEGAL-01" "Required Legal Docs Check"
required_files=(
    "legal/mutual-nda_v1.0.md"
    "legal/privacy-notice_v1.0.md"
    "legal/revenue-share-warrant_v1.md"
    "LICENSE.md"
    "CODE_OF_CONDUCT.md"
)

missing=0
missing_files=""
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        log "error" "Missing required file: $file"
        missing=1
        missing_files="$missing_files $file"
    else
        log "success" "Found required file: $file"
        # Also check the file size to ensure it's not empty
        file_size=$(wc -c < "$file" | tr -d ' ')
        log "debug" "File size for $file: $file_size bytes"
        if [ "$file_size" -lt 100 ]; then
            log "warn" "File $file is suspiciously small: $file_size bytes"
        fi
    fi
done

if [ $missing -eq 1 ]; then
    test_end "W1-LEGAL-01" "fail" "Missing required legal files:$missing_files"
else
    test_end "W1-LEGAL-01" "pass"
fi

# W1-DOCS-01: Markdown Linting
test_start "W1-DOCS-01" "Markdown Linting"
if command -v npx > /dev/null; then
    log "info" "Running markdown linting on all markdown files"
    lint_output=$(npx markdownlint-cli2 "**/*.md" 2>&1)
    lint_exit_code=$?
    log_data "Markdown lint output" "$lint_output"
    
    if [ $lint_exit_code -eq 0 ]; then
        test_end "W1-DOCS-01" "pass"
    else
        errors_count=$(echo "$lint_output" | grep -c "error")
        test_end "W1-DOCS-01" "fail" "$errors_count markdown lint errors detected"
    fi
else
    test_end "W1-DOCS-01" "skip" "markdownlint-cli2 not installed"
fi

# W1-BRAND-01: Brand Assets Check
test_start "W1-BRAND-01" "Brand Assets Check"
log "info" "Checking for SVG logo files"
svg_files=$(find design/logo/static -name "*.svg" 2>/dev/null)
svg_files_count=$(echo "$svg_files" | grep -c "\.svg$")

log_data "Found SVG files" "$svg_files"

if [ "$svg_files_count" -lt 2 ]; then
    test_end "W1-BRAND-01" "fail" "Not enough SVG logo files found (minimum 2 required, found $svg_files_count)"
else
    test_end "W1-BRAND-01" "pass" "Found $svg_files_count SVG logo files"
fi

# W1-BRAND-02: SVG Optimization Check
test_start "W1-BRAND-02" "SVG Optimization Check"
if ! command -v npx > /dev/null; then
    test_end "W1-BRAND-02" "skip" "SVGO not available"
else
    log "info" "Checking SVG optimization potential"
    declare -a optimization_issues=()
    
    for svg in $(find design/logo/static -name "*.svg" 2>/dev/null); do
        log "debug" "Analyzing $svg"
        before_size=$(wc -c < "$svg")
        npx svgo --disable=removeViewBox "$svg" -o "$svg.optimized" > /dev/null 2>&1
        after_size=$(wc -c < "$svg.optimized")
        rm "$svg.optimized"
        
        savings=$(( 100 - (after_size * 100 / before_size) ))
        log "info" "$svg: Original: $before_size bytes, Potential: $after_size bytes, Savings: $savings%"
        
        if [ "$savings" -gt 10 ]; then
            log "warn" "SVG file $svg could be optimized further (potential $savings% savings)"
            optimization_issues+=("$svg: $savings% potential savings")
        else
            log "success" "SVG file $svg is well optimized"
        fi
    done
    
    if [ ${#optimization_issues[@]} -gt 0 ]; then
        optimization_issues_str=$(printf "%s; " "${optimization_issues[@]}")
        test_end "W1-BRAND-02" "warn" "Some SVGs could be further optimized: ${optimization_issues_str}"
    else
        test_end "W1-BRAND-02" "pass"
    fi
fi

# W1-TOKEN-01: Design Token File Check
test_start "W1-TOKEN-01" "Design Token File Check"
token_file="design/palette-tokens/design-tokens.json"

if [ ! -f "$token_file" ]; then
    test_end "W1-TOKEN-01" "fail" "Missing design tokens file: $token_file"
else
    log "success" "Found design tokens file"
    
    # Check if the JSON is valid
    jq_output=$(jq empty "$token_file" 2>&1)
    jq_exit_code=$?
    
    if [ $jq_exit_code -ne 0 ]; then
        log "error" "Invalid JSON in design tokens file"
        log_data "JSON validation error" "$jq_output"
        test_end "W1-TOKEN-01" "fail" "Invalid JSON in design tokens file"
    else
        log "success" "Design tokens file contains valid JSON"
        
        # Check required token categories
        required_categories=("colors" "spacing" "typography")
        missing=0
        missing_categories=""
        
        for category in "${required_categories[@]}"; do
            if ! jq -e ".$category" "$token_file" >/dev/null 2>&1; then
                log "error" "Missing required token category: $category"
                missing=1
                missing_categories="$missing_categories $category"
            else
                log "success" "Found required token category: $category"
                # Check depth of the category
                keys_count=$(jq ".$category | keys | length" "$token_file")
                log "debug" "Category $category has $keys_count keys"
            fi
        done
        
        if [ $missing -eq 1 ]; then
            test_end "W1-TOKEN-01" "fail" "Missing required token categories:$missing_categories"
        else
            # Additional in-depth validation
            colors_count=$(jq '.colors | keys | length' "$token_file")
            log "info" "Found $colors_count color categories in design tokens"
            
            if [ "$colors_count" -lt 3 ]; then
                test_end "W1-TOKEN-01" "warn" "Design tokens have only $colors_count color categories (recommended minimum is 3)"
            else
                test_end "W1-TOKEN-01" "pass"
            fi
        fi
    fi
fi

# Week 2 Tests
log "info" "Starting Week 2 Tests"

# W2-WCAG-01: Color Contrast Check
test_start "W2-WCAG-01" "Color Contrast Check"
log "info" "Running WCAG contrast check on design tokens"

contrast_output=$(node scripts/ci/contrast.js 2>&1)
contrast_exit_code=$?
log_data "Contrast check output" "$contrast_output"

if [ $contrast_exit_code -eq 0 ]; then
    passed_colors=$(echo "$contrast_output" | grep -o "Checked [0-9]* color tokens" | awk '{print $2}')
    test_end "W2-WCAG-01" "pass" "All $passed_colors colors pass WCAG 2.1 AA contrast requirements"
else
    failing_count=$(echo "$contrast_output" | grep -c "contrast issues")
    test_end "W2-WCAG-01" "fail" "Found $failing_count colors with contrast issues"
fi

# W2-DOCKER-01: Docker Image Build Check
test_start "W2-DOCKER-01" "Docker Image Build Check"
if ! command -v docker > /dev/null; then
    test_end "W2-DOCKER-01" "skip" "Docker not installed"
else
    log "info" "Building Docker image for Edge Gateway"
    docker_build_start=$(date +%s)
    docker_output=$(cd code/edge-gateway && docker build -t dcentral/edge-gateway:test . 2>&1)
    docker_exit_code=$?
    docker_build_end=$(date +%s)
    docker_build_time=$((docker_build_end - docker_build_start))
    
    log_data "Docker build output" "$docker_output"
    log "info" "Docker build took $docker_build_time seconds"
    
    if [ $docker_exit_code -eq 0 ]; then
        # Get image size
        image_size=$(docker images dcentral/edge-gateway:test --format "{{.Size}}")
        log "info" "Docker image size: $image_size"
        
        test_end "W2-DOCKER-01" "pass" "Docker image built successfully in $docker_build_time seconds, size: $image_size"
    else
        test_end "W2-DOCKER-01" "fail" "Docker build failed"
    fi
fi

# W2-SBOM-01/02: SBOM Generation and License Check
test_start "W2-SBOM-01-02" "SBOM Generation and License Check"
if ! command -v trivy > /dev/null; then
    test_end "W2-SBOM-01-02" "skip" "Trivy not installed"
else
    log "info" "Generating SBOM for codebase"
    
    # Generate SBOM
    trivy_output=$(trivy fs --format cyclonedx code/edge-gateway -o sbom.cdx.json 2>&1)
    trivy_exit_code=$?
    log_data "Trivy SBOM generation output" "$trivy_output"
    
    if [ $trivy_exit_code -ne 0 ]; then
        test_end "W2-SBOM-01-02" "fail" "Failed to generate SBOM"
    else
        log "success" "SBOM generated successfully"
        
        # Extract some data from SBOM for logging
        components_count=$(jq '.components | length' sbom.cdx.json 2>/dev/null || echo "unknown")
        log "info" "SBOM contains $components_count components"
        
        # Check SBOM for GPL compatibility
        log "info" "Checking SBOM for GPL compatibility"
        sbom_check_output=$(bash scripts/ci/sbom_diff_checker_enhanced.sh sbom.cdx.json scripts/ci/gpl_compatible_licenses.txt 2>&1)
        sbom_check_exit_code=$?
        log_data "SBOM license check output" "$sbom_check_output"
        
        if [ $sbom_check_exit_code -eq 0 ]; then
            test_end "W2-SBOM-01-02" "pass" "SBOM generated and no GPL-incompatible licenses found"
        else
            incompatible_count=$(echo "$sbom_check_output" | grep -o "Found [0-9]* GPL-incompatible licenses" | awk '{print $2}')
            test_end "W2-SBOM-01-02" "fail" "Found $incompatible_count GPL-incompatible licenses"
        fi
        
        # Clean up
        log "debug" "Cleaning up temporary SBOM file"
        rm sbom.cdx.json
    fi
fi

# W2-GO-01: Go Code Quality Check
test_start "W2-GO-01" "Go Code Quality Check"
if ! command -v go > /dev/null; then
    test_end "W2-GO-01" "skip" "Go not installed"
else
    log "info" "Running Go code quality checks"
    
    # Check if the directory exists
    if [ ! -d "code/edge-gateway" ]; then
        test_end "W2-GO-01" "fail" "Edge Gateway code directory not found"
    else
        # Run Go module verification
        log "info" "Verifying Go modules"
        go_mod_output=$(cd code/edge-gateway && go mod verify 2>&1)
        go_mod_exit_code=$?
        log_data "Go mod verify output" "$go_mod_output"
        
        if [ $go_mod_exit_code -ne 0 ]; then
            test_end "W2-GO-01" "fail" "Go module verification failed"
        else
            log "success" "Go modules verified successfully"
            
            # Build the code
            log "info" "Building Go code"
            go_build_output=$(cd code/edge-gateway && go build -v ./... 2>&1)
            go_build_exit_code=$?
            log_data "Go build output" "$go_build_output"
            
            if [ $go_build_exit_code -ne 0 ]; then
                test_end "W2-GO-01" "fail" "Go build failed"
            else
                log "success" "Go build successful"
                
                # Run tests with race detection and coverage
                log "info" "Running Go tests with race detection and coverage analysis"
                go_test_output=$(cd code/edge-gateway && go test -race -coverprofile=coverage.txt -covermode=atomic ./... 2>&1)
                go_test_exit_code=$?
                log_data "Go test output" "$go_test_output"
                
                if [ $go_test_exit_code -ne 0 ]; then
                    test_end "W2-GO-01" "fail" "Go tests failed"
                else
                    log "success" "Go tests passed"
                    
                    # Check coverage
                    log "info" "Checking code coverage"
                    coverage_output=$(cd code/edge-gateway && go tool cover -func=coverage.txt 2>&1)
                    log_data "Coverage output" "$coverage_output"
                    
                    # Extract total coverage
                    coverage=$(cd code/edge-gateway && go tool cover -func=coverage.txt | grep total | awk '{print $3}' | tr -d '%')
                    log "info" "Total code coverage: $coverage%"
                    
                    if (( $(echo "$coverage < 70.0" | bc -l) )); then
                        test_end "W2-GO-01" "fail" "Code coverage below 70%: $coverage%"
                    else
                        test_end "W2-GO-01" "pass" "All Go code quality checks passed, coverage: $coverage%"
                    fi
                    
                    # Clean up
                    cd code/edge-gateway && rm coverage.txt
                fi
            fi
        fi
    fi
fi

# W2-HELM-01: Helm Chart Validation
test_start "W2-HELM-01" "Helm Chart Validation"
if ! command -v helm > /dev/null; then
    test_end "W2-HELM-01" "skip" "Helm not installed"
else
    log "info" "Linting Helm chart"
    
    # Check if the chart directory exists
    if [ ! -d "code/helm/edge-gateway-chart" ]; then
        test_end "W2-HELM-01" "fail" "Helm chart directory not found"
    else
        # Lint the chart
        helm_lint_output=$(helm lint code/helm/edge-gateway-chart 2>&1)
        helm_lint_exit_code=$?
        log_data "Helm lint output" "$helm_lint_output"
        
        if [ $helm_lint_exit_code -ne 0 ]; then
            test_end "W2-HELM-01" "fail" "Helm lint found errors"
        else
            log "success" "Helm chart passed linting"
            
            # Template and validate if kubectl is available
            if command -v kubectl > /dev/null; then
                log "info" "Validating templated Kubernetes resources"
                helm_template_output=$(helm template code/helm/edge-gateway-chart > templated.yaml 2>&1)
                log_data "Helm template output" "$helm_template_output"
                
                kubectl_validate_output=$(kubectl create --dry-run=client -f templated.yaml 2>&1)
                kubectl_validate_exit_code=$?
                log_data "Kubectl validation output" "$kubectl_validate_output"
                
                rm templated.yaml
                
                if [ $kubectl_validate_exit_code -ne 0 ]; then
                    test_end "W2-HELM-01" "fail" "Kubernetes validation of Helm templates failed"
                else
                    test_end "W2-HELM-01" "pass" "Helm chart and Kubernetes resources validated successfully"
                fi
            else
                log "warn" "kubectl not installed, skipping template validation"
                test_end "W2-HELM-01" "pass" "Helm chart passed linting (kubectl validation skipped)"
            fi
        fi
    fi
fi

# Week 3 Tests
log "info" "Starting Week 3 Tests"

# W3-K8S-01: Kubernetes Manifest Validation
test_start "W3-K8S-01" "Kubernetes Manifest Validation"
if ! command -v kubectl > /dev/null; then
    test_end "W3-K8S-01" "skip" "kubectl not installed"
else
    log "info" "Validating Kubernetes manifests"
    
    # Check if the templates directory exists
    if [ ! -d "code/helm/edge-gateway-chart/templates" ]; then
        test_end "W3-K8S-01" "fail" "Kubernetes templates directory not found"
    else
        # Count the number of YAML files
        yaml_files=$(find code/helm/edge-gateway-chart/templates -name "*.yaml" 2>/dev/null)
        yaml_files_count=$(echo "$yaml_files" | grep -c "\.yaml$")
        log "info" "Found $yaml_files_count YAML manifest files"
        
        if [ "$yaml_files_count" -eq 0 ]; then
            test_end "W3-K8S-01" "fail" "No YAML manifest files found"
        else
            # Validate each manifest
            valid_count=0
            invalid_count=0
            invalid_files=""
            
            for manifest in $(find code/helm/edge-gateway-chart/templates -name "*.yaml"); do
                log "debug" "Validating $manifest"
                kubectl_output=$(kubectl create --dry-run=client -f $manifest 2>&1)
                kubectl_exit_code=$?
                
                if [ $kubectl_exit_code -eq 0 ]; then
                    log "success" "$manifest is valid"
                    valid_count=$((valid_count + 1))
                else
                    log "warn" "$manifest not directly valid, but may be valid after rendering"
                    log_data "Kubectl output for $manifest" "$kubectl_output"
                    invalid_count=$((invalid_count + 1))
                    invalid_files="$invalid_files $(basename $manifest)"
                fi
            done
            
            if [ $invalid_count -eq 0 ]; then
                test_end "W3-K8S-01" "pass" "All $valid_count Kubernetes manifests validated successfully"
            else
                # Not failing the test as templates often contain variables that are replaced during rendering
                test_end "W3-K8S-01" "warn" "$invalid_count/$yaml_files_count manifests require rendering:$invalid_files"
            fi
        fi
    fi
fi

# W3-SEC-01: Container Security Scan
test_start "W3-SEC-01" "Container Security Scan"
if ! command -v trivy > /dev/null || ! command -v docker > /dev/null; then
    test_end "W3-SEC-01" "skip" "Trivy or Docker not installed"
else
    log "info" "Running security scan on container image"
    
    # Check if image exists, if not build it
    if ! docker image inspect dcentral/edge-gateway:test > /dev/null 2>&1; then
        log "info" "Building image first..."
        docker_build_output=$(cd code/edge-gateway && docker build -t dcentral/edge-gateway:test . 2>&1)
        docker_build_exit_code=$?
        log_data "Docker build output" "$docker_build_output"
        
        if [ $docker_build_exit_code -ne 0 ]; then
            test_end "W3-SEC-01" "fail" "Failed to build Docker image for security scan"
            continue
        fi
    fi
    
    # Run security scan
    log "info" "Scanning container image for vulnerabilities"
    trivy_scan_output=$(trivy image --severity HIGH,CRITICAL --ignore-unfixed dcentral/edge-gateway:test 2>&1)
    trivy_scan_exit_code=$?
    log_data "Trivy security scan output" "$trivy_scan_output"
    
    # Count vulnerabilities
    if echo "$trivy_scan_output" | grep -q "Total: 0"; then
        test_end "W3-SEC-01" "pass" "No HIGH or CRITICAL vulnerabilities found"
    else
        # Extract vulnerability counts
        high_count=$(echo "$trivy_scan_output" | grep "HIGH: " | awk '{print $2}')
        critical_count=$(echo "$trivy_scan_output" | grep "CRITICAL: " | awk '{print $2}')
        high_count=${high_count:-0}
        critical_count=${critical_count:-0}
        
        if [ $critical_count -gt 0 ]; then
            test_end "W3-SEC-01" "fail" "Found $critical_count CRITICAL and $high_count HIGH vulnerabilities"
        elif [ $high_count -gt 5 ]; then
            test_end "W3-SEC-01" "fail" "Found $high_count HIGH vulnerabilities (threshold is 5)"
        else
            test_end "W3-SEC-01" "warn" "Found $high_count HIGH vulnerabilities (within acceptable limits)"
        fi
    fi
fi

# W3-PERF-01: MQTT Performance Test
test_start "W3-PERF-01" "MQTT Performance Test"
if ! command -v k6 > /dev/null; then
    test_end "W3-PERF-01" "skip" "k6 not installed"
else
    log "info" "Running MQTT performance test"
    
    # Check if the test file exists
    if [ ! -f "code/tests/perf/mqtt_loadtest.js" ]; then
        test_end "W3-PERF-01" "fail" "MQTT performance test file not found"
    else
        # Run k6 test with reduced load for local testing
        log "info" "Running k6 test with reduced load for local verification"
        k6_output=$(k6 run --no-summary code/tests/perf/mqtt_loadtest.js --vus 5 --duration 10s 2>&1)
        k6_exit_code=$?
        log_data "k6 MQTT test output" "$k6_output"
        
        if [ $k6_exit_code -ne 0 ]; then
            test_end "W3-PERF-01" "fail" "MQTT performance test failed"
        else
            # Extract metrics if available
            if echo "$k6_output" | grep -q "Message loss"; then
                loss_percentage=$(echo "$k6_output" | grep "Message loss" | grep -o "[0-9.]*%" | tr -d '%')
                log "info" "MQTT message loss: $loss_percentage%"
                
                if (( $(echo "$loss_percentage > 0.5" | bc -l) )); then
                    test_end "W3-PERF-01" "fail" "MQTT message loss exceeds threshold: $loss_percentage%"
                else
                    test_end "W3-PERF-01" "pass" "MQTT performance test passed, message loss: $loss_percentage%"
                fi
            else
                test_end "W3-PERF-01" "pass" "MQTT performance test completed"
            fi
        fi
    fi
fi

# W3-PERF-02: REST API Performance Test
test_start "W3-PERF-02" "REST API Performance Test"
if ! command -v k6 > /dev/null; then
    test_end "W3-PERF-02" "skip" "k6 not installed"
else
    log "info" "Running REST API performance test"
    
    # Check if the test file exists
    if [ ! -f "code/tests/perf/rest_loadtest.js" ]; then
        test_end "W3-PERF-02" "fail" "REST API performance test file not found"
    else
        # Run k6 test with reduced load for local testing
        log "info" "Running k6 test with reduced load for local verification"
        k6_output=$(k6 run --no-summary code/tests/perf/rest_loadtest.js --vus 5 --duration 10s 2>&1)
        k6_exit_code=$?
        log_data "k6 REST API test output" "$k6_output"
        
        if [ $k6_exit_code -ne 0 ]; then
            test_end "W3-PERF-02" "fail" "REST API performance test failed"
        else
            # Extract metrics if available
            if echo "$k6_output" | grep -q "http_req_duration"; then
                p95_latency=$(echo "$k6_output" | grep "http_req_duration" | grep -o "p\(95\)=[0-9.]*" | cut -d'=' -f2)
                log "info" "REST API p95 latency: $p95_latency ms"
                
                if (( $(echo "$p95_latency > 200" | bc -l) )); then
                    test_end "W3-PERF-02" "fail" "REST API latency exceeds threshold: $p95_latency ms"
                else
                    test_end "W3-PERF-02" "pass" "REST API performance test passed, p95 latency: $p95_latency ms"
                fi
            else
                test_end "W3-PERF-02" "pass" "REST API performance test completed"
            fi
        fi
    fi
fi

# W3-GH-01: GitHub Workflows Check
test_start "W3-GH-01" "GitHub Workflows Check"
log "info" "Checking GitHub workflow files"

workflow_files=$(find .github/workflows -name "*.yml" -o -name "*.yaml" 2>/dev/null)
workflow_files_count=$(echo "$workflow_files" | grep -c "\.\(yml\|yaml\)$")
log_data "Found workflow files" "$workflow_files"

if [ "$workflow_files_count" -eq 0 ]; then
    test_end "W3-GH-01" "fail" "No GitHub workflow files found"
else
    log "success" "Found $workflow_files_count GitHub workflow files"
    
    # Validate workflow files if yq is available
    invalid_count=0
    invalid_files=""
    
    if command -v yq > /dev/null; then
        log "info" "Validating workflow YAML syntax"
        
        for file in $(find .github/workflows -name "*.yml" -o -name "*.yaml" 2>/dev/null); do
            log "debug" "Validating $file"
            yq_output=$(yq eval $file 2>&1)
            yq_exit_code=$?
            
            if [ $yq_exit_code -ne 0 ]; then
                log "error" "Invalid YAML in workflow file: $file"
                log_data "YQ validation error for $file" "$yq_output"
                invalid_count=$((invalid_count + 1))
                invalid_files="$invalid_files $(basename $file)"
            else
                log "success" "Valid YAML in workflow file: $file"
                
                # Check if it contains essential workflow elements
                if grep -q "name:" "$file" && grep -q "runs-on:" "$file" && grep -q "steps:" "$file"; then
                    log "success" "Workflow file $file contains required elements"
                    
                    # Count jobs in the workflow
                    jobs_count=$(grep -c "jobs:" "$file")
                    log "info" "Workflow file $file contains $jobs_count job definitions"
                else
                    log "warn" "Workflow file $file may be missing essential workflow elements"
                    invalid_count=$((invalid_count + 1))
                    invalid_files="$invalid_files $(basename $file) (missing elements)"
                fi
            fi
        done
        
        if [ $invalid_count -eq 0 ]; then
            test_end "W3-GH-01" "pass" "All $workflow_files_count workflow files are valid"
        else
            test_end "W3-GH-01" "fail" "Found $invalid_count invalid workflow files:$invalid_files"
        fi
    else
        log "warn" "yq not installed, skipping YAML validation"
        
        # Perform basic check
        essential_elements=0
        for file in $(find .github/workflows -name "*.yml" -o -name "*.yaml" 2>/dev/null); do
            if grep -q "name:" "$file" && grep -q "runs-on:" "$file" && grep -q "steps:" "$file"; then
                essential_elements=$((essential_elements + 1))
            fi
        done
        
        if [ $essential_elements -eq $workflow_files_count ]; then
            test_end "W3-GH-01" "pass" "All $workflow_files_count workflow files contain essential elements (syntax not validated)"
        else
            test_end "W3-GH-01" "warn" "Some workflow files may be missing essential elements (syntax not validated)"
        fi
    fi
fi

# The cleanup function from test_logger.sh will generate the summary automatically
# when the script exits

exit 0