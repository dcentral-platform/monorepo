FROM golang:1.21-bullseye AS builder

WORKDIR /app

# Copy and download dependencies
COPY go.mod go.sum* ./
RUN go mod download && go mod verify

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o edge-gateway .

# Use Debian slim as the final image
FROM debian:bullseye-slim

# Install ca-certificates for secure connections
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy the binary from the builder stage
COPY --from=builder /app/edge-gateway /app/

# Create a non-root user and set permissions
RUN useradd -u 10001 dcentral && \
    chown -R dcentral:dcentral /app

USER dcentral

# Expose MQTT port
EXPOSE 1883

# Set entry point
ENTRYPOINT ["/app/edge-gateway"]