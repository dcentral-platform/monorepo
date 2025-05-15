#!/bin/bash
# test_logger.sh - Comprehensive logging utility for test suite
# This script provides standardized logging functions for all tests

# Configuration
LOG_DIR="${CI_LOG_DIR:-logs/ci}"
LOG_LEVEL="${CI_LOG_LEVEL:-info}" # debug, info, warn, error
LOG_RETENTION_DAYS="${CI_LOG_RETENTION_DAYS:-30}"
TIMESTAMP_FORMAT="%Y-%m-%d %H:%M:%S"
TEST_SESSION_ID=$(date +%Y%m%d_%H%M%S)_$(openssl rand -hex 4)

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Log file paths
CURRENT_LOG_FILE=""
SUMMARY_LOG_FILE="$LOG_DIR/test_summary_$TEST_SESSION_ID.log"
JSON_SUMMARY_FILE="$LOG_DIR/test_summary_$TEST_SESSION_ID.json"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Test summary data
declare -A TEST_RESULTS
declare -A TEST_DURATIONS
TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
SKIP_COUNT=0

# Initialize JSON summary
echo "{" > "$JSON_SUMMARY_FILE"
echo "  \"session_id\": \"$TEST_SESSION_ID\"," >> "$JSON_SUMMARY_FILE"
echo "  \"start_time\": \"$(date +"$TIMESTAMP_FORMAT")\"," >> "$JSON_SUMMARY_FILE"
echo "  \"tests\": [" >> "$JSON_SUMMARY_FILE"

# Function to determine if we should log based on level
should_log() {
    local level=$1
    case $LOG_LEVEL in
        debug)
            return 0
            ;;
        info)
            [[ "$level" != "debug" ]] && return 0 || return 1
            ;;
        warn)
            [[ "$level" == "warn" || "$level" == "error" ]] && return 0 || return 1
            ;;
        error)
            [[ "$level" == "error" ]] && return 0 || return 1
            ;;
    esac
}

# Log a message to both console and log file
# Usage: log <level> <message>
log() {
    local level=$1
    local message=$2
    local timestamp=$(date +"$TIMESTAMP_FORMAT")
    local color=""
    local prefix=""
    
    # Check if we should log this message
    should_log "$level" || return 0
    
    # Determine color and prefix based on level
    case $level in
        debug)
            color=$GRAY
            prefix="DEBUG"
            ;;
        info)
            color=$BLUE
            prefix="INFO "
            ;;
        warn)
            color=$YELLOW
            prefix="WARN "
            ;;
        error)
            color=$RED
            prefix="ERROR"
            ;;
        success)
            color=$GREEN
            prefix="OK   "
            ;;
    esac
    
    # Create formatted log message
    local console_msg="${color}${prefix}${NC} [${timestamp}] ${message}"
    local file_msg="${prefix} [${timestamp}] ${message}"
    
    # Log to console
    echo -e "$console_msg"
    
    # Log to current test log file
    if [[ -n "$CURRENT_LOG_FILE" ]]; then
        echo "$file_msg" >> "$CURRENT_LOG_FILE"
    fi
    
    # Also log errors and warnings to summary
    if [[ "$level" == "error" || "$level" == "warn" || "$level" == "success" ]]; then
        echo "$file_msg" >> "$SUMMARY_LOG_FILE"
    fi
}

# Initialize a test
# Usage: test_start <test_id> <test_description>
test_start() {
    local test_id=$1
    local description=$2
    local timestamp=$(date +"$TIMESTAMP_FORMAT")
    
    # Increment test counter
    TEST_COUNT=$((TEST_COUNT + 1))
    
    # Create log file for this test
    CURRENT_LOG_FILE="$LOG_DIR/${test_id}_$TEST_SESSION_ID.log"
    touch "$CURRENT_LOG_FILE"
    
    # Record start time
    TEST_START_TIME=$(date +%s)
    
    # Add separator to summary log
    echo -e "\n------------------------------------------------" >> "$SUMMARY_LOG_FILE"
    
    # Log test start
    log "info" "${BOLD}STARTING TEST:${NC} $test_id - $description"
    echo "INFO [${timestamp}] STARTING TEST: $test_id - $description" >> "$SUMMARY_LOG_FILE"
    
    # Add comma for previous test entry except for first test
    if [[ $TEST_COUNT -gt 1 ]]; then
        # Remove new line at end of JSON summary and add comma and new line
        truncate -s-1 "$JSON_SUMMARY_FILE"
        echo "," >> "$JSON_SUMMARY_FILE"
    fi
    
    # Start JSON entry for this test
    cat >> "$JSON_SUMMARY_FILE" << EOF
    {
      "test_id": "$test_id",
      "description": "$description",
      "start_time": "$timestamp",
EOF
}

# Mark a test as complete
# Usage: test_end <test_id> <status> [message]
# Status should be "pass", "fail", "warn", or "skip"
test_end() {
    local test_id=$1
    local status=$2
    local message=${3:-""}
    local timestamp=$(date +"$TIMESTAMP_FORMAT")
    local duration=$(($(date +%s) - TEST_START_TIME))
    
    # Store test result and duration
    TEST_RESULTS["$test_id"]=$status
    TEST_DURATIONS["$test_id"]=$duration
    
    # Update counters
    case $status in
        pass)
            PASS_COUNT=$((PASS_COUNT + 1))
            log "success" "${BOLD}PASS:${NC} $test_id ($duration seconds)"
            echo "SUCCESS [${timestamp}] PASS: $test_id ($duration seconds) $message" >> "$SUMMARY_LOG_FILE"
            ;;
        fail)
            FAIL_COUNT=$((FAIL_COUNT + 1))
            log "error" "${BOLD}FAIL:${NC} $test_id ($duration seconds) - $message"
            echo "ERROR [${timestamp}] FAIL: $test_id ($duration seconds) - $message" >> "$SUMMARY_LOG_FILE"
            ;;
        warn)
            WARN_COUNT=$((WARN_COUNT + 1))
            log "warn" "${BOLD}WARN:${NC} $test_id ($duration seconds) - $message"
            echo "WARN [${timestamp}] WARN: $test_id ($duration seconds) - $message" >> "$SUMMARY_LOG_FILE"
            ;;
        skip)
            SKIP_COUNT=$((SKIP_COUNT + 1))
            log "info" "${BOLD}SKIP:${NC} $test_id ($duration seconds) - $message"
            echo "INFO [${timestamp}] SKIP: $test_id ($duration seconds) - $message" >> "$SUMMARY_LOG_FILE"
            ;;
    esac
    
    # Finish JSON entry for this test
    cat >> "$JSON_SUMMARY_FILE" << EOF
      "end_time": "$timestamp",
      "duration_seconds": $duration,
      "status": "$status",
      "message": "$message",
      "log_file": "$(basename "$CURRENT_LOG_FILE")"
    }
EOF
    
    # Reset current log file
    CURRENT_LOG_FILE=""
}

# Log detailed data (helpful for debugging)
# Usage: log_data <name> <data>
log_data() {
    local name=$1
    local data=$2
    
    # Only log if debug level is enabled
    should_log "debug" || return 0
    
    log "debug" "${BOLD}$name:${NC}"
    echo "$data" | while IFS= read -r line; do
        log "debug" "  $line"
    done
}

# Log a command's output
# Usage: log_cmd <command> [args...]
log_cmd() {
    local cmd="$@"
    local output
    local exit_code
    
    log "debug" "Running command: $cmd"
    
    # Capture both output and exit code
    output=$("$@" 2>&1)
    exit_code=$?
    
    # Log the command output
    if [[ -n "$output" ]]; then
        log_data "Command output" "$output"
    fi
    
    # Return the original exit code
    return $exit_code
}

# Generate final summary
generate_summary() {
    local end_timestamp=$(date +"$TIMESTAMP_FORMAT")
    local total_duration=$(($(date +%s) - $(date -j -f "%Y-%m-%d %H:%M:%S" "$(grep "start_time" "$JSON_SUMMARY_FILE" | cut -d'"' -f4)" +%s)))
    
    # Add summary separator
    echo -e "\n================================================" >> "$SUMMARY_LOG_FILE"
    echo "SUMMARY [${end_timestamp}] TEST RESULTS:" >> "$SUMMARY_LOG_FILE"
    echo "Total tests: $TEST_COUNT" >> "$SUMMARY_LOG_FILE"
    echo "Passed: $PASS_COUNT" >> "$SUMMARY_LOG_FILE"
    echo "Failed: $FAIL_COUNT" >> "$SUMMARY_LOG_FILE"
    echo "Warnings: $WARN_COUNT" >> "$SUMMARY_LOG_FILE"
    echo "Skipped: $SKIP_COUNT" >> "$SUMMARY_LOG_FILE"
    echo "Total duration: $total_duration seconds" >> "$SUMMARY_LOG_FILE"
    
    # Log summary to console
    echo -e "\n${BOLD}${BLUE}================================================${NC}"
    echo -e "${BOLD}TEST SUMMARY:${NC}"
    echo -e "Total tests: ${BOLD}$TEST_COUNT${NC}"
    echo -e "Passed: ${GREEN}${BOLD}$PASS_COUNT${NC}"
    echo -e "Failed: ${RED}${BOLD}$FAIL_COUNT${NC}"
    echo -e "Warnings: ${YELLOW}${BOLD}$WARN_COUNT${NC}"
    echo -e "Skipped: ${GRAY}${BOLD}$SKIP_COUNT${NC}"
    echo -e "Total duration: ${BOLD}$total_duration seconds${NC}"
    
    # Complete JSON summary
    cat >> "$JSON_SUMMARY_FILE" << EOF
  ],
  "summary": {
    "end_time": "$end_timestamp",
    "total_duration_seconds": $total_duration,
    "total_tests": $TEST_COUNT,
    "passed": $PASS_COUNT,
    "failed": $FAIL_COUNT,
    "warnings": $WARN_COUNT,
    "skipped": $SKIP_COUNT
  }
}
EOF
    
    # Print path to logs
    echo -e "\n${BLUE}Log files saved to:${NC} $LOG_DIR"
    echo -e "${BLUE}Summary log:${NC} $SUMMARY_LOG_FILE"
    echo -e "${BLUE}JSON summary:${NC} $JSON_SUMMARY_FILE"
    
    # Clean up old logs
    find "$LOG_DIR" -type f -name "*.log" -mtime +$LOG_RETENTION_DAYS -delete
    find "$LOG_DIR" -type f -name "*.json" -mtime +$LOG_RETENTION_DAYS -delete
}

# Register cleanup for graceful termination
cleanup() {
    # If any tests were started but not completed, mark them as failed
    if [[ -n "$CURRENT_LOG_FILE" ]]; then
        test_end "$(basename "$CURRENT_LOG_FILE" | cut -d'_' -f1)" "fail" "Test was interrupted"
    fi
    
    # Generate summary
    generate_summary
}

# Register trap
trap cleanup EXIT INT TERM

# Export functions for use in other scripts
export -f log log_data log_cmd test_start test_end should_log