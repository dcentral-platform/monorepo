# D Central Test Suite - Weeks 1-3

This document provides an overview of the test suite implemented for the D Central project covering Weeks 1-3 deliverables. The test suite ensures that all components of the project comply with the defined standards and requirements.

## Test Suite Architecture

The test suite is implemented as:

1. **GitHub Actions Workflow**: Located at `.github/workflows/test-suite.yml` and `.github/workflows/test-suite-enhanced.yml`
2. **Local Verification Script**: Located at `scripts/verification/verify_weeks1-3.sh` and `scripts/verification/verify_weeks1-3_enhanced.sh`
3. **Developer Tools**: Pre-commit hooks and just tasks for local development
4. **Comprehensive Logging System**: Located at `scripts/ci/test_logger.sh` with analysis tools

## Test Categories

### Week 1 Tests

| Test ID | Description | Test Tool |
|---------|-------------|-----------|
| W1-REPO-01 | Repository Structure Check | `scripts/ci/tree_assert.py` |
| W1-LEGAL-01 | Required Legal Docs Check | Bash script verification |
| W1-DOCS-01 | Markdown Linting | markdownlint-cli |
| W1-BRAND-01 | Brand Assets Check | Directory/file verification |
| W1-BRAND-02 | SVG Optimization Check | SVGO |
| W1-TOKEN-01 | Design Token File Check | JSON validation |

### Week 2 Tests

| Test ID | Description | Test Tool |
|---------|-------------|-----------|
| W2-WCAG-01 | Color Contrast Check | `scripts/ci/contrast.js` |
| W2-DOCKER-01 | Docker Image Build Check | Docker build |
| W2-SBOM-01 | SBOM Generation | Trivy |
| W2-SBOM-02 | License Compatibility Check | `scripts/ci/sbom_diff_checker_enhanced.sh` |
| W2-GO-01 | Go Code Quality Check | Go test with race detector & coverage |
| W2-HELM-01 | Helm Chart Validation | Helm lint |

### Week 3 Tests

| Test ID | Description | Test Tool |
|---------|-------------|-----------|
| W3-K8S-01 | Kubernetes Manifest Validation | kubectl validate |
| W3-SEC-01 | Container Security Scan | Trivy |
| W3-PERF-01 | MQTT Performance Test | k6 with `code/tests/perf/mqtt_loadtest.js` |
| W3-PERF-02 | REST API Performance Test | k6 with `code/tests/perf/rest_loadtest.js` |
| W3-GH-01 | GitHub Workflows Check | YAML validation |

## Running Tests

### GitHub Actions

Tests will run automatically on push to main/develop branches and on PRs to these branches. You can also run the workflow manually.

#### Enhanced Workflow

The enhanced workflow (`test-suite-enhanced.yml`) includes:

- Comprehensive logging for all test steps
- Detailed test artifacts with pass/fail information
- Visualization of test results in the GitHub UI
- Automated test summary generation
- Performance metrics collection and reporting

### Local Development

For local development, you can use the following commands:

```bash
# Run all verification tests for Weeks 1-3
./scripts/verification/verify_weeks1-3.sh

# Run enhanced verification with comprehensive logging
./scripts/verification/verify_weeks1-3_enhanced.sh

# Run specific test categories using just
just preflight           # Run all linting checks
just lint-md             # Check markdown files
just lint-svg            # Check SVG files
just lint-go             # Run Go linters
just helm-lint           # Verify Helm charts
just test-go             # Run Go tests
just security-scan       # Run security scan
just docker-build        # Build Docker image
just generate-sbom       # Generate SBOM
just check-contrast      # Run WCAG contrast check
just verify-structure    # Verify directory structure
```

## Pre-commit Hooks

Pre-commit hooks are configured in `.pre-commit-config.yaml` to ensure code quality before committing. Install pre-commit and set up the hooks:

```bash
pip install pre-commit
pre-commit install
```

## Comprehensive Logging System

The test suite includes a comprehensive logging system that provides detailed insights into test execution:

### Features

1. **Structured Logging**: All test output follows a consistent format
2. **Log Levels**: Support for debug, info, warning, error, and success messages
3. **JSON Test Summaries**: Machine-readable test results
4. **HTML Reports**: Visual representation of test results
5. **CSV Export**: Data export for further analysis
6. **Trend Analysis**: Compare results across multiple test runs
7. **Test Artifacts**: Each test generates its own log file
8. **GitHub Integration**: Log artifacts are uploaded to GitHub Actions

### Log Utilities

The following utilities are provided for log analysis:

- **logs_to_html.sh**: Convert JSON summaries to HTML reports
- **logs_to_csv.sh**: Convert JSON summaries to CSV format
- **analyze_logs.py**: Python tool for advanced log analysis and visualization

For more details, see the [Test Logging Documentation](docs/test-logging.md).

## Recommended Developer Workflow

1. Make your changes
2. Run `just preflight` to verify your changes locally
3. Run `./scripts/verification/verify_weeks1-3_enhanced.sh` for a comprehensive check
4. Commit and push your changes
5. The GitHub Actions will run all tests automatically

## Integration with Branch Protection

We recommend setting up branch protection rules in GitHub to require tests to pass before PRs can be merged:

1. Go to the repository settings
2. Navigate to Branches > Branch protection rules
3. Add a rule for the main branch
4. Check "Require status checks to pass before merging"
5. Select all the workflow checks from the test suite

This will ensure all code changes meet the quality and security standards established by the test suite.