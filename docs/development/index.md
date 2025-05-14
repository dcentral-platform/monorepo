# Development Guide

This guide provides information for developers who want to contribute to the D Central Platform or build applications that integrate with it.

## Prerequisites

- **Go 1.21+** - For backend development
- **Node.js 18+** - For frontend and smart contract development
- **Docker** - For containerized development and testing
- **Kubernetes** - For deployment (k3s recommended for local testing)

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/dcentral-platform/monorepo.git
   cd monorepo
   ```

2. Set up the development environment:
   ```bash
   # Install Go dependencies
   cd code/edge-gateway
   go mod download
   
   # Install Node.js dependencies
   cd ../..
   npm install
   ```

3. Run the local development server:
   ```bash
   # For edge gateway
   cd code/edge-gateway
   go run main.go
   
   # For frontend (in another terminal)
   npm run dev
   ```

## Project Structure

- `code/edge-gateway` - Go code for the edge gateway
- `code/contracts` - Solidity smart contracts
- `docs` - Documentation source files
- `design` - UI/UX design assets and tokens
- `scripts` - Development and CI/CD scripts

## Contribution Guidelines

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

For more details, see [CONTRIBUTING.md](https://github.com/dcentral-platform/monorepo/blob/main/CONTRIBUTING.md).

## Testing

Run tests for each component:

```bash
# Go tests
cd code/edge-gateway
go test ./...

# Smart contract tests
cd code/contracts
npx hardhat test

# Frontend tests
npm test
```