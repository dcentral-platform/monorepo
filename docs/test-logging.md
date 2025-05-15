# D Central Test Logging Framework

This document provides an overview of the comprehensive logging framework implemented for the D Central project test suite. The logging system ensures detailed and consistent reporting of test results, making debugging and traceability easier.

## Overview

The test logging framework provides:

1. **Structured Logging**: Consistent log format across all tests
2. **Test Session Tracking**: Unique session IDs for each test run
3. **Log Levels**: Support for debug, info, warn, error, and success
4. **JSON Reports**: Machine-readable test results
5. **Human-Readable Summaries**: Clear pass/fail indicators with details
6. **Log Retention**: Automatic cleanup of old logs
7. **Artifact Integration**: GitHub Actions artifact upload for persistence

## File Structure

- **Test Logger**: `scripts/ci/test_logger.sh`
- **Enhanced Verification Script**: `scripts/verification/verify_weeks1-3_enhanced.sh`
- **Enhanced GitHub Workflow**: `.github/workflows/test-suite-enhanced.yml`

## Log Directory Structure

Logs are saved in the following structure:

```
logs/
├── ci/                      # CI logs from GitHub Actions
│   ├── test_summary_[SESSION_ID].log      # Text summary of all test results
│   ├── test_summary_[SESSION_ID].json     # JSON summary of all test results
│   ├── [TEST_ID]_[SESSION_ID].log         # Individual test logs
├── verification/            # Local verification logs
│   ├── ...                  # Same structure as above
```

## Using the Logging Framework

### In Scripts

To use the logging framework in your scripts:

```bash
# Source the test logger
source scripts/ci/test_logger.sh

# Start a test
test_start "TEST-ID" "Test Description"

# Log information
log "info" "Running some operation"

# Log detailed data
log_data "Command output" "$output"

# Run a command and log its output
log_cmd some_command --with-args

# End the test with a result
test_end "TEST-ID" "pass" "Optional details"
# Or for failure
test_end "TEST-ID" "fail" "Reason for failure"
# Or for warnings
test_end "TEST-ID" "warn" "Warning details"
```

### In GitHub Actions

The enhanced GitHub Actions workflow automatically:

1. Sets up the logging environment
2. Runs tests with comprehensive logging
3. Uploads log artifacts for each test
4. Generates a summary report
5. Provides job-level status dashboard

## Log Levels

The following log levels are supported:

- `debug`: Detailed diagnostic information
- `info`: General information about test progress
- `warn`: Warning conditions that should be addressed
- `error`: Error conditions that caused a test to fail
- `success`: Successful operations

You can set the `CI_LOG_LEVEL` environment variable to control which messages are displayed and logged.

## JSON Summary Format

The JSON summary file has the following structure:

```json
{
  "session_id": "20250514_120000_abcd1234",
  "start_time": "2025-05-14 12:00:00",
  "tests": [
    {
      "test_id": "W1-REPO-01",
      "description": "Repository Structure Check",
      "start_time": "2025-05-14 12:00:05",
      "end_time": "2025-05-14 12:00:10",
      "duration_seconds": 5,
      "status": "pass",
      "message": "All directory checks passed",
      "log_file": "W1-REPO-01_20250514_120000_abcd1234.log"
    },
    // More test results...
  ],
  "summary": {
    "end_time": "2025-05-14 12:05:00",
    "total_duration_seconds": 300,
    "total_tests": 20,
    "passed": 18,
    "failed": 1,
    "warnings": 1,
    "skipped": 0
  }
}
```

## Environment Variables

The logging system supports the following environment variables:

- `CI_LOG_DIR`: Directory where logs are stored (default: `logs/ci`)
- `CI_LOG_LEVEL`: Minimum log level to display (`debug`, `info`, `warn`, `error`) (default: `info`)
- `CI_LOG_RETENTION_DAYS`: Number of days to keep logs (default: `30`)

## Best Practices

1. **Test Naming**: Use consistent test IDs with clear prefixes
2. **Meaningful Messages**: Provide detailed information in log messages
3. **Contextual Data**: Use `log_data` to include detailed outputs
4. **Failure Context**: Always explain the reason for failures
5. **Log Command Outputs**: Use `log_cmd` to capture command outputs

## Integration with GitHub Actions

The enhanced GitHub Actions workflow automatically:

1. Creates a log directory for each job
2. Uploads logs as job artifacts
3. Generates a test summary report as a workflow summary
4. Integrates test results with the GitHub Checks API

## Analyzing Test Failures

When a test fails:

1. Check the job output in GitHub Actions
2. Download the log artifacts for the failed job
3. Look for the `[TEST_ID]_[SESSION_ID].log` file
4. Review the detailed diagnostic information
5. Check the `test_summary_[SESSION_ID].log` for context

## Generating Reports

The test summary can be converted to different formats:

```bash
# Generate HTML report from JSON summary
scripts/ci/logs_to_html.sh logs/ci/test_summary_[SESSION_ID].json > report.html

# Generate CSV report from JSON summary
scripts/ci/logs_to_csv.sh logs/ci/test_summary_[SESSION_ID].json > report.csv
```

## Conclusion

This comprehensive logging framework provides detailed insight into test execution, making it easier to identify issues, track test progress, and maintain a record of test results over time. The consistent format and rich metadata make it suitable for both human analysis and automated processing.