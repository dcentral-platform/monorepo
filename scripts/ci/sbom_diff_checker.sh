#!/bin/bash
# sbom_diff_checker.sh
# Script to check for differences between current and previous SBOMs (Software Bill of Materials)
# This helps identify new dependencies and potential security issues in CI/CD pipelines

set -euo pipefail

# Configuration variables
SBOM_TOOL=${SBOM_TOOL:-"cyclonedx-cli"}
PREVIOUS_SBOM_PATH=${PREVIOUS_SBOM_PATH:-"./sbom/previous.json"}
CURRENT_SBOM_PATH=${CURRENT_SBOM_PATH:-"./sbom/current.json"}
OUTPUT_PATH=${OUTPUT_PATH:-"./sbom/diff-report.json"}
SEVERITY_THRESHOLD=${SEVERITY_THRESHOLD:-"medium"}
SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL:-""}
JIRA_API_TOKEN=${JIRA_API_TOKEN:-""}
JIRA_PROJECT=${JIRA_PROJECT:-"DCENTRAL"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display usage information
usage() {
  echo "Usage: $0 [options]"
  echo
  echo "Options:"
  echo "  -p, --previous PATH    Path to previous SBOM file (default: $PREVIOUS_SBOM_PATH)"
  echo "  -c, --current PATH     Path to current SBOM file (default: $CURRENT_SBOM_PATH)"
  echo "  -o, --output PATH      Path for output diff report (default: $OUTPUT_PATH)"
  echo "  -t, --threshold LEVEL  Severity threshold (low, medium, high, critical) (default: $SEVERITY_THRESHOLD)"
  echo "  -h, --help             Display this help message and exit"
  echo
  echo "Environment variables:"
  echo "  SBOM_TOOL              Tool to use for SBOM comparison (default: cyclonedx-cli)"
  echo "  SLACK_WEBHOOK_URL      Slack webhook URL for notifications"
  echo "  JIRA_API_TOKEN         Jira API token for creating tickets"
  echo "  JIRA_PROJECT           Jira project key (default: DCENTRAL)"
}

# Function to check if required tools are installed
check_dependencies() {
  echo "Checking dependencies..."
  
  if ! command -v "$SBOM_TOOL" &> /dev/null; then
    echo -e "${RED}Error: $SBOM_TOOL not found.${NC}"
    echo "Please install the required SBOM tool:"
    echo "  For cyclonedx-cli: npm install -g @cyclonedx/cyclonedx-cli"
    echo "  For syft: curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin"
    exit 1
  fi
  
  if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq not found.${NC}"
    echo "Please install jq: https://stedolan.github.io/jq/download/"
    exit 1
  fi
  
  echo -e "${GREEN}All dependencies are installed.${NC}"
}

# Function to generate current SBOM if it doesn't exist
generate_current_sbom() {
  if [ ! -f "$CURRENT_SBOM_PATH" ]; then
    echo "Generating current SBOM..."
    mkdir -p "$(dirname "$CURRENT_SBOM_PATH")"
    
    case "$SBOM_TOOL" in
      cyclonedx-cli)
        echo "Using cyclonedx-cli to generate SBOM..."
        # This is a placeholder. In practice, you would use a tool like cyclonedx-npm, syft, etc.
        echo "{\"bomFormat\":\"CycloneDX\",\"specVersion\":\"1.4\",\"serialNumber\":\"urn:uuid:$(uuidgen)\",\"version\":1,\"components\":[]}" > "$CURRENT_SBOM_PATH"
        ;;
      syft)
        echo "Using syft to generate SBOM..."
        syft packages . -o cyclonedx-json > "$CURRENT_SBOM_PATH"
        ;;
      *)
        echo -e "${RED}Unsupported SBOM tool: $SBOM_TOOL${NC}"
        exit 1
        ;;
    esac
  else
    echo "Using existing current SBOM at $CURRENT_SBOM_PATH"
  fi
}

# Function to perform diff between SBOMs
perform_diff() {
  echo "Performing diff between previous and current SBOMs..."
  
  if [ ! -f "$PREVIOUS_SBOM_PATH" ]; then
    echo -e "${YELLOW}Warning: Previous SBOM not found at $PREVIOUS_SBOM_PATH${NC}"
    echo "This appears to be the first run. Copying current SBOM as previous for future runs."
    mkdir -p "$(dirname "$PREVIOUS_SBOM_PATH")"
    cp "$CURRENT_SBOM_PATH" "$PREVIOUS_SBOM_PATH"
    echo "{\"added\": [], \"removed\": [], \"changed\": []}" > "$OUTPUT_PATH"
    return 0
  fi
  
  mkdir -p "$(dirname "$OUTPUT_PATH")"
  
  case "$SBOM_TOOL" in
    cyclonedx-cli)
      cyclonedx-cli diff --from-file "$PREVIOUS_SBOM_PATH" --to-file "$CURRENT_SBOM_PATH" --output-format json > "$OUTPUT_PATH"
      ;;
    *)
      # Custom diff using jq
      echo "Performing custom diff using jq..."
      jq -n --argfile prev "$PREVIOUS_SBOM_PATH" --argfile curr "$CURRENT_SBOM_PATH" \
        '{
          "added": [($curr.components // [])[] | select(.purl != null) | 
            select(($prev.components // [])[] | select(.purl != null).purl | contains(.purl) | not)],
          "removed": [($prev.components // [])[] | select(.purl != null) | 
            select(($curr.components // [])[] | select(.purl != null).purl | contains(.purl) | not)],
          "changed": []
        }' > "$OUTPUT_PATH"
      ;;
  esac
  
  echo -e "${GREEN}Diff completed and saved to $OUTPUT_PATH${NC}"
}

# Function to analyze vulnerabilities in added components
analyze_vulnerabilities() {
  echo "Analyzing vulnerabilities in added components..."
  
  # Count of added components
  ADDED_COUNT=$(jq '.added | length' "$OUTPUT_PATH")
  
  if [ "$ADDED_COUNT" -eq 0 ]; then
    echo -e "${GREEN}No new components were added.${NC}"
    return 0
  fi
  
  echo -e "${YELLOW}Found $ADDED_COUNT new components added.${NC}"
  
  # In a real implementation, this would call a vulnerability scanner
  # like Trivy, Grype, or a service like Snyk or Dependabot.
  echo "This is a placeholder for vulnerability scanning."
  echo "In production, integrate with a vulnerability scanner of choice."
  
  # Simulate finding vulnerabilities for demonstration purposes
  VULN_COUNT=0
  HIGH_VULN_COUNT=0
  
  if [ "$ADDED_COUNT" -gt 2 ]; then
    VULN_COUNT=$((ADDED_COUNT / 2))
    HIGH_VULN_COUNT=$((VULN_COUNT / 2))
  fi
  
  if [ "$HIGH_VULN_COUNT" -gt 0 ]; then
    echo -e "${RED}Found $HIGH_VULN_COUNT high severity vulnerabilities!${NC}"
    if [ "$SEVERITY_THRESHOLD" = "high" ] || [ "$SEVERITY_THRESHOLD" = "critical" ]; then
      echo "High severity vulnerabilities found, but below threshold of $SEVERITY_THRESHOLD."
      return 0
    else
      return 1
    fi
  else
    echo -e "${GREEN}No high severity vulnerabilities found.${NC}"
    return 0
  fi
}

# Function to send notifications
send_notifications() {
  local status=$1
  
  if [ -n "$SLACK_WEBHOOK_URL" ]; then
    echo "Sending notification to Slack..."
    
    ADDED_COUNT=$(jq '.added | length' "$OUTPUT_PATH")
    REMOVED_COUNT=$(jq '.removed | length' "$OUTPUT_PATH")
    
    local color="good"
    local status_text="passed"
    
    if [ "$status" -ne 0 ]; then
      color="danger"
      status_text="failed"
    fi
    
    curl -s -X POST -H 'Content-type: application/json' \
      --data "{
        \"attachments\": [
          {
            \"color\": \"$color\",
            \"title\": \"SBOM Diff Check $status_text\",
            \"text\": \"Found $ADDED_COUNT new dependencies and $REMOVED_COUNT removed dependencies.\",
            \"fields\": [
              {
                \"title\": \"Branch\",
                \"value\": \"${GITHUB_REF_NAME:-Unknown}\",
                \"short\": true
              },
              {
                \"title\": \"Repository\",
                \"value\": \"${GITHUB_REPOSITORY:-Unknown}\",
                \"short\": true
              }
            ]
          }
        ]
      }" "$SLACK_WEBHOOK_URL" > /dev/null
    
    echo "Slack notification sent."
  fi
  
  # Create Jira ticket for failures
  if [ "$status" -ne 0 ] && [ -n "$JIRA_API_TOKEN" ]; then
    echo "Creating Jira ticket for vulnerability findings..."
    echo "This is a placeholder for Jira integration."
  fi
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -p|--previous)
      PREVIOUS_SBOM_PATH="$2"
      shift 2
      ;;
    -c|--current)
      CURRENT_SBOM_PATH="$2"
      shift 2
      ;;
    -o|--output)
      OUTPUT_PATH="$2"
      shift 2
      ;;
    -t|--threshold)
      SEVERITY_THRESHOLD="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo -e "${RED}Error: Unknown option: $1${NC}" >&2
      usage
      exit 1
      ;;
  esac
done

# Main execution
main() {
  echo "=== DCentral SBOM Diff Checker ==="
  echo "Comparing SBOMs to identify changes in dependencies"
  echo
  
  check_dependencies
  generate_current_sbom
  perform_diff
  
  # Analyze vulnerabilities and capture exit status
  analyze_vulnerabilities
  VULN_STATUS=$?
  
  # Create artifacts directory
  mkdir -p ./artifacts
  cp "$OUTPUT_PATH" ./artifacts/
  
  # Update previous SBOM for next run
  cp "$CURRENT_SBOM_PATH" "$PREVIOUS_SBOM_PATH"
  
  # Send notifications based on vulnerability status
  send_notifications $VULN_STATUS
  
  if [ $VULN_STATUS -ne 0 ]; then
    echo -e "${RED}SBOM diff check failed due to vulnerability threshold exceeded.${NC}"
    exit $VULN_STATUS
  fi
  
  echo -e "${GREEN}SBOM diff check completed successfully.${NC}"
}

main