# Justfile for D Central Project
# This file defines common development tasks

# Show all available recipes
@default:
    just --list

# Run a complete preflight check before committing
preflight: lint-md lint-svg lint-go helm-lint

# Run all linters
lint: lint-md lint-svg lint-go

# Check markdown files with markdownlint
lint-md:
    @echo "Checking markdown files..."
    npx markdownlint-cli2 "**/*.md"

# Clean SVG files with SVGO
lint-svg:
    @echo "Checking SVG files..."
    cd design/logo/static && npx svgo --pretty --multipass --dry-run *.svg

# Run Go linters if Go is installed
lint-go:
    @echo "Checking Go code..."
    if command -v go > /dev/null; then \
        cd code/edge-gateway && go vet ./...; \
    else \
        echo "Go not installed, skipping Go checks"; \
    fi

# Verify Helm charts
helm-lint:
    @echo "Checking Helm charts..."
    if command -v helm > /dev/null; then \
        helm lint code/helm/edge-gateway-chart; \
    else \
        echo "Helm not installed, skipping Helm checks"; \
    fi

# Run tests for Go code
test-go:
    @echo "Running Go tests..."
    if command -v go > /dev/null; then \
        cd code/edge-gateway && go test ./...; \
    else \
        echo "Go not installed, skipping Go tests"; \
    fi

# Run security scan on codebase
security-scan:
    @echo "Running security scan..."
    if command -v trivy > /dev/null; then \
        trivy fs .; \
    else \
        echo "Trivy not installed, skipping security scan"; \
    fi

# Build Docker image for edge-gateway
docker-build:
    @echo "Building Docker image..."
    cd code/edge-gateway && docker build -t dcentral/edge-gateway:test .

# Run SBOM generation
generate-sbom:
    @echo "Generating SBOM..."
    if command -v trivy > /dev/null; then \
        trivy image --format spdx-json -o edge-gateway_sbom.spdx.json dcentral/edge-gateway:test; \
    else \
        echo "Trivy not installed, skipping SBOM generation"; \
    fi

# Run WCAG contrast check on design tokens
check-contrast:
    @echo "Checking color contrast..."
    node scripts/ci/contrast.js

# Create directory tree manifest
create-manifest:
    @echo "Creating directory manifest..."
    python scripts/ci/tree_assert.py --create-manifest

# Verify directory structure
verify-structure:
    @echo "Verifying directory structure..."
    python scripts/ci/tree_assert.py

# Setup development environment
setup-dev:
    @echo "Setting up development environment..."
    npm install -g markdownlint-cli2 svgo
    pip install mkdocs mkdocs-material pyyaml pytest

# Run all verification tests
verify-all: preflight test-go security-scan check-contrast verify-structure
    @echo "All verification tests completed!"