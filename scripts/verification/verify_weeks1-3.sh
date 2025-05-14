#!/bin/bash
# DCentral Project Verification Script for Weeks 1-3
# This script verifies the accuracy and integrity of all work completed in Weeks 1-3
# by checking file existence, content quality, and task completion.

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Repository root detection
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

echo -e "${BLUE}==================================${NC}"
echo -e "${BLUE}= DCentral Project Verification =${NC}"
echo -e "${BLUE}=        Weeks 1-3 Check        =${NC}"
echo -e "${BLUE}==================================${NC}"

# Verification results counter
TOTAL=0
PASSED=0
WARNINGS=0
FAILED=0

# Function to check if a file exists
check_file() {
  TOTAL=$((TOTAL+1))
  if [ -f "$1" ]; then
    echo -e "${GREEN}✓ File exists:${NC} $1"
    PASSED=$((PASSED+1))
    return 0
  else
    echo -e "${RED}✗ File missing:${NC} $1"
    FAILED=$((FAILED+1))
    return 1
  fi
}

# Function to check if a directory exists
check_dir() {
  TOTAL=$((TOTAL+1))
  if [ -d "$1" ]; then
    echo -e "${GREEN}✓ Directory exists:${NC} $1"
    PASSED=$((PASSED+1))
    return 0
  else
    echo -e "${RED}✗ Directory missing:${NC} $1"
    FAILED=$((FAILED+1))
    return 1
  fi
}

# Function to check file content for specific string
check_content() {
  TOTAL=$((TOTAL+1))
  if [ -f "$1" ] && grep -q "$2" "$1"; then
    echo -e "${GREEN}✓ Content verified:${NC} $2 in $1"
    PASSED=$((PASSED+1))
    return 0
  else
    echo -e "${RED}✗ Content missing:${NC} $2 in $1"
    FAILED=$((FAILED+1))
    return 1
  fi
}

# Function to check file size (ensures it's not empty or too small)
check_file_size() {
  TOTAL=$((TOTAL+1))
  if [ -f "$1" ]; then
    size=$(wc -c < "$1")
    if [ "$size" -ge "$2" ]; then
      echo -e "${GREEN}✓ File size adequate:${NC} $1 ($size bytes)"
      PASSED=$((PASSED+1))
      return 0
    else
      echo -e "${YELLOW}⚠ File too small:${NC} $1 ($size bytes, expected >= $2)"
      WARNINGS=$((WARNINGS+1))
      return 1
    fi
  else
    echo -e "${RED}✗ File missing for size check:${NC} $1"
    FAILED=$((FAILED+1))
    return 1
  fi
}

# Function to check JSON validity
check_json() {
  TOTAL=$((TOTAL+1))
  if [ -f "$1" ]; then
    if jq empty "$1" 2>/dev/null; then
      echo -e "${GREEN}✓ Valid JSON:${NC} $1"
      PASSED=$((PASSED+1))
      return 0
    else
      echo -e "${RED}✗ Invalid JSON:${NC} $1"
      FAILED=$((FAILED+1))
      return 1
    fi
  else
    echo -e "${RED}✗ JSON file missing:${NC} $1"
    FAILED=$((FAILED+1))
    return 1
  fi
}

# Function to check SVG validity
check_svg() {
  TOTAL=$((TOTAL+1))
  if [ -f "$1" ]; then
    if grep -q "<svg" "$1" && grep -q "</svg>" "$1"; then
      echo -e "${GREEN}✓ Valid SVG:${NC} $1"
      PASSED=$((PASSED+1))
      return 0
    else
      echo -e "${RED}✗ Invalid SVG:${NC} $1 (missing SVG tags)"
      FAILED=$((FAILED+1))
      return 1
    fi
  else
    echo -e "${RED}✗ SVG file missing:${NC} $1"
    FAILED=$((FAILED+1))
    return 1
  fi
}

# Function to check Go file compilation
check_go_compile() {
  TOTAL=$((TOTAL+1))
  if [ -f "$1" ]; then
    if cd "$(dirname "$1")" && go build -o /dev/null "$(basename "$1")" 2>/dev/null; then
      echo -e "${GREEN}✓ Go file compiles:${NC} $1"
      PASSED=$((PASSED+1))
      cd - > /dev/null
      return 0
    else
      echo -e "${RED}✗ Go file does not compile:${NC} $1"
      FAILED=$((FAILED+1))
      cd - > /dev/null
      return 1
    fi
  else
    echo -e "${RED}✗ Go file missing:${NC} $1"
    FAILED=$((FAILED+1))
    return 1
  fi
}

# Function to check YAML validity
check_yaml() {
  TOTAL=$((TOTAL+1))
  if [ -f "$1" ]; then
    if yamllint -d relaxed "$1" >/dev/null 2>&1; then
      echo -e "${GREEN}✓ Valid YAML:${NC} $1"
      PASSED=$((PASSED+1))
      return 0
    else
      echo -e "${YELLOW}⚠ YAML validation issues:${NC} $1"
      WARNINGS=$((WARNINGS+1))
      return 1
    fi
  else
    echo -e "${RED}✗ YAML file missing:${NC} $1"
    FAILED=$((FAILED+1))
    return 1
  fi
}

# Function to check workflow syntax
check_github_workflow() {
  TOTAL=$((TOTAL+1))
  if [ -f "$1" ]; then
    if grep -q "name:" "$1" && grep -q "runs-on:" "$1"; then
      echo -e "${GREEN}✓ GitHub workflow looks valid:${NC} $1"
      PASSED=$((PASSED+1))
      return 0
    else
      echo -e "${RED}✗ GitHub workflow missing key elements:${NC} $1"
      FAILED=$((FAILED+1))
      return 1
    fi
  else
    echo -e "${RED}✗ GitHub workflow file missing:${NC} $1"
    FAILED=$((FAILED+1))
    return 1
  fi
}

echo -e "\n${BLUE}▶ Checking Week 1: Repository Setup and Legal Documents${NC}"

# Week 1 Task 1: Init repo
check_dir ".git"
check_file "README.md"
check_file_size "README.md" 100

# Week 1 Task 2-3: Legal documents
check_file "legal/mutual-nda_v1.0.md"
check_content "legal/mutual-nda_v1.0.md" "Ontario law"
check_content "legal/mutual-nda_v1.0.md" "2-year term"
check_file_size "legal/mutual-nda_v1.0.md" 500

check_file "legal/revenue-share-warrant_v1.md"
check_content "legal/revenue-share-warrant_v1.md" "1%"
check_content "legal/revenue-share-warrant_v1.md" "non-transferable"
check_file_size "legal/revenue-share-warrant_v1.md" 500

# Week 1 Task 4: Push repo to GitHub
if [ -n "$(git remote -v | grep github)" ]; then
  echo -e "${GREEN}✓ GitHub remote exists${NC}"
  PASSED=$((PASSED+1))
else
  echo -e "${RED}✗ GitHub remote not found${NC}"
  FAILED=$((FAILED+1))
fi
TOTAL=$((TOTAL+1))

# Week 1 Task 5: LICENSE files
check_file "LICENSE.md"
check_file "LICENSE.txt"
check_content "LICENSE.md" "GPL"
check_content "LICENSE.md" "CC BY"

# Week 1 Task 7: Privacy Notice
check_file "legal/privacy-notice_v1.0.md"
check_content "legal/privacy-notice_v1.0.md" "GDPR"
check_content "legal/privacy-notice_v1.0.md" "PIPEDA"
check_file_size "legal/privacy-notice_v1.0.md" 1000

# Week 1 Task 8: GitHub Actions
check_file ".github/workflows/build.yml"
check_github_workflow ".github/workflows/build.yml"
check_file ".github/workflows/security.yml"
check_github_workflow ".github/workflows/security.yml"

# Week 1 Task 9: Folder Structure
check_dir "code"
check_dir "design"
check_dir "docs"
check_dir "legal"
check_dir "scripts"
check_dir "scripts/roadmap"
check_file "scripts/roadmap/tasks.yaml"
check_file_size "scripts/roadmap/tasks.yaml" 1000

echo -e "\n${BLUE}▶ Checking Week 2: Design System Implementation${NC}"

# Week 2 Task 1-2: Logo files
check_dir "design/logo/renders"
check_file_size "design/logo/renders/mesh-node_v1.png" 5000
check_dir "design/logo/static"
check_svg "design/logo/static/dcentral-logo-primary.svg"
check_svg "design/logo/static/dcentral-logo-simple.svg"

# Week 2 Task 3: Design tokens
check_file "design/palette-tokens/design-tokens.json"
check_json "design/palette-tokens/design-tokens.json"
check_content "design/palette-tokens/design-tokens.json" "colors"
check_content "design/palette-tokens/design-tokens.json" "primary"
check_content "design/palette-tokens/design-tokens.json" "secondary"

# Week 2 Task 4: Tailwind config
check_file "design/tailwind.config.js"
check_content "design/tailwind.config.js" "module.exports"
check_content "design/tailwind.config.js" "theme"
check_content "design/tailwind.config.js" "colors"

# Week 2 Task 5: Storybook
check_dir "design/storybook"
check_file "design/storybook/package.json"
check_json "design/storybook/package.json"
check_dir "design/storybook/components"
check_file "design/storybook/components/Button.jsx"
check_file "design/storybook/components/Button.stories.jsx"

# Week 2 Task 6-7: WCAG check and Brand Guide
check_file "design/figma-exports/WCAG_results.md"
check_content "design/figma-exports/WCAG_results.md" "Contrast Ratio"
check_file "design/figma-exports/brand-guide.md"
check_file_size "design/figma-exports/brand-guide.md" 500

echo -e "\n${BLUE}▶ Checking Week 3: Edge Gateway MVP${NC}"

# Week 3 Task 1: Edge Gateway Go module
check_dir "code/edge-gateway"
check_file "code/edge-gateway/main.go"
check_file "code/edge-gateway/go.mod"
check_content "code/edge-gateway/go.mod" "github.com/dcentral-platform/monorepo/edge-gateway"

# Week 3 Task 2: Dockerfile
check_file "code/edge-gateway/Dockerfile"
check_content "code/edge-gateway/Dockerfile" "FROM"
check_content "code/edge-gateway/Dockerfile" "bullseye"

# Week 3 Task 3: MQTT client
check_file "code/edge-gateway/mqtt_client.go"
check_content "code/edge-gateway/mqtt_client.go" "MQTTClient"
check_content "code/edge-gateway/mqtt_client.go" "Connect"
check_file_size "code/edge-gateway/mqtt_client.go" 1000

# Week 3 Task 4: Unit tests
check_file "code/edge-gateway/main_test.go"
check_file "code/edge-gateway/mqtt_client_test.go"
check_content "code/edge-gateway/mqtt_client_test.go" "TestMQTTClient"
check_file_size "code/edge-gateway/mqtt_client_test.go" 500

# Week 3 Task 5: Helm chart
check_dir "code/helm/edge-gateway-chart"
check_file "code/helm/edge-gateway-chart/Chart.yaml"
check_file "code/helm/edge-gateway-chart/values.yaml"
check_dir "code/helm/edge-gateway-chart/templates"
check_file "code/helm/edge-gateway-chart/templates/deployment.yaml"
check_content "code/helm/edge-gateway-chart/templates/deployment.yaml" "kind: Deployment"

# Week 3 Task 6: K6 Performance test
check_dir "code/tests/perf"
check_file "code/tests/perf/edge-gateway-k6.js"
check_content "code/tests/perf/edge-gateway-k6.js" "import { check"
check_file_size "code/tests/perf/edge-gateway-k6.js" 500

# Week 3 Task 8: SBOM diff checker
check_file "scripts/ci/sbom_diff_checker.sh"
check_content "scripts/ci/sbom_diff_checker.sh" "SBOM"
check_file_size "scripts/ci/sbom_diff_checker.sh" 1000

# Check completion reports
check_file "Week1_Completion.md"
check_file "Week2_Completion.md"
check_file "Week3_Completion.md"

# Final summary
echo -e "\n${BLUE}========= Verification Summary ==========${NC}"
echo -e "Total checks: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

PASS_PERCENTAGE=$((PASSED * 100 / TOTAL))
echo -e "Completion rate: $PASS_PERCENTAGE%"

if [ $FAILED -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo -e "\n${GREEN}✅ All verification checks passed successfully!${NC}"
  EXIT_CODE=0
elif [ $FAILED -eq 0 ] && [ $WARNINGS -gt 0 ]; then
  echo -e "\n${YELLOW}⚠️ Verification completed with warnings. Please review.${NC}"
  EXIT_CODE=0
else
  echo -e "\n${RED}❌ Verification failed. Please fix the issues listed above.${NC}"
  EXIT_CODE=1
fi

exit $EXIT_CODE