# DCentral Partner Integration Guide

## Overview

This guide provides instructions for third-party partners to integrate with the DCentral platform. It covers authentication, API endpoints, webhooks, and best practices for building on top of our infrastructure.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Authentication](#authentication)
3. [API Overview](#api-overview)
4. [Webhooks](#webhooks)
5. [SDKs and Libraries](#sdks-and-libraries)
6. [Testing and Sandbox](#testing-and-sandbox)
7. [Going to Production](#going-to-production)
8. [Support and Resources](#support-and-resources)

## Getting Started

### Prerequisites

To integrate with the DCentral platform, you'll need:

- A DCentral Partner account
- API credentials (Client ID and Client Secret)
- Basic understanding of RESTful APIs
- Familiarity with blockchain concepts (for blockchain-specific features)

### Registration Process

1. Visit [partners.dcentral.io](https://partners.dcentral.io) to create a partner account
2. Complete the application form
3. Once approved, you'll receive your API credentials
4. Set up your integration in the Partner Dashboard

## Authentication

DCentral uses OAuth 2.0 for API authentication. The following grant types are supported:

- Client Credentials (for server-to-server)
- Authorization Code (for user-delegated access)

### Obtaining an Access Token

```bash
curl -X POST https://api.dcentral.io/v1/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=YOUR_CLIENT_ID&client_secret=YOUR_CLIENT_SECRET"
```

Response:

```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "scope": "read:users write:data"
}
```

### Using the Access Token

Include the token in the Authorization header for all API requests:

```bash
curl -X GET https://api.dcentral.io/v1/resources \
  -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
```

## API Overview

### Base URL

- Production: `https://api.dcentral.io/v1`
- Sandbox: `https://sandbox-api.dcentral.io/v1`

### Response Format

All API responses are in JSON format and include:

```json
{
  "data": {},            // The response data
  "meta": {              // Metadata about the request
    "request_id": "abc123",
    "timestamp": "2023-10-15T12:34:56Z"
  },
  "pagination": {        // For list endpoints
    "total": 100,
    "page": 1,
    "per_page": 25,
    "next_page": 2
  }
}
```

### Error Handling

Error responses include:

```json
{
  "error": {
    "code": "validation_error",
    "message": "The provided data is invalid",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      }
    ]
  },
  "meta": {
    "request_id": "def456",
    "timestamp": "2023-10-15T12:34:56Z"
  }
}
```

### Rate Limiting

- 1,000 requests per minute per API key
- Limits indicated in response headers:
  - `X-RateLimit-Limit`: Total requests allowed
  - `X-RateLimit-Remaining`: Requests remaining
  - `X-RateLimit-Reset`: Time when limit resets (Unix timestamp)

### Core Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/users` | GET | List users |
| `/users/{id}` | GET | Get user details |
| `/assets` | GET | List digital assets |
| `/assets/{id}` | GET | Get asset details |
| `/transactions` | POST | Create a new transaction |
| `/transactions/{id}` | GET | Get transaction details |
| `/wallets` | GET | List wallets |
| `/wallets/{id}/balance` | GET | Get wallet balance |

## Webhooks

DCentral uses webhooks to notify your application about events in real-time.

### Setting Up Webhooks

1. Go to the Partner Dashboard
2. Navigate to Webhooks section
3. Add a new webhook URL
4. Select events to subscribe to
5. Save your configuration

### Webhook Events

| Event Type | Description |
|------------|-------------|
| `user.created` | A new user has been created |
| `transaction.initiated` | A transaction has been initiated |
| `transaction.completed` | A transaction has been completed |
| `transaction.failed` | A transaction has failed |
| `asset.transferred` | An asset has been transferred |
| `wallet.updated` | A wallet has been updated |

### Webhook Format

```json
{
  "id": "evt_123456",
  "type": "transaction.completed",
  "created": "2023-10-15T12:34:56Z",
  "data": {
    "transaction_id": "txn_abcdef",
    "amount": "10.5",
    "currency": "DCNT",
    "status": "completed",
    "user_id": "usr_123456"
  }
}
```

### Verifying Webhooks

To ensure webhooks are coming from DCentral, verify the signature:

1. Get the signature from the `X-DCentral-Signature` header
2. Compute an HMAC with the SHA256 hash function
3. Use your webhook secret as the key and the raw request body as the message
4. Compare the signature with the header value

## SDKs and Libraries

We provide official SDKs for common languages:

- JavaScript/Node.js: `npm install @dcentral/sdk`
- Python: `pip install dcentral-sdk`
- Java: Available on Maven Central
- Go: `go get github.com/dcentral/go-sdk`

### Example (Node.js)

```javascript
const DCentral = require('@dcentral/sdk');

// Initialize the client
const client = new DCentral.Client({
  clientId: 'YOUR_CLIENT_ID',
  clientSecret: 'YOUR_CLIENT_SECRET',
  environment: 'sandbox' // or 'production'
});

// Make API calls
async function getUsers() {
  try {
    const users = await client.users.list();
    console.log(users);
  } catch (error) {
    console.error('Error fetching users:', error);
  }
}

getUsers();
```

## Testing and Sandbox

The sandbox environment allows you to test your integration without affecting production data.

### Sandbox Credentials

Separate API credentials are required for the sandbox environment. Create them in the Partner Dashboard.

### Test Data

The sandbox is pre-populated with test data:

- Test users
- Test assets
- Test wallets with balances

### Testing Tools

- API request builder in the Partner Dashboard
- Webhook event simulator
- Transaction simulator

## Going to Production

Before moving to production, ensure you've:

1. Thoroughly tested your integration in the sandbox
2. Implemented proper error handling and retry logic
3. Set up monitoring for your integration
4. Secured your API credentials and webhook endpoints
5. Completed the security review (for certain integration types)

### Production Checklist

- [ ] Update API endpoints to production URLs
- [ ] Update API credentials to production credentials
- [ ] Configure production webhook URLs
- [ ] Set up alerts for error conditions
- [ ] Document your integration for internal teams

## Support and Resources

- [Developer Documentation](https://developers.dcentral.io)
- [API Reference](https://developers.dcentral.io/api)
- [SDKs and Libraries](https://developers.dcentral.io/sdks)
- [Community Forum](https://community.dcentral.io)
- [Support Email](mailto:partners@dcentral.io)

### Getting Help

For technical issues, contact us through:

- Partner Dashboard support ticket
- Email: partners@dcentral.io
- Emergency Support: +1-XXX-XXX-XXXX (for production outages)

---

**Note**: This documentation is a placeholder. Actual endpoints, parameters, and response formats will be defined as the platform is developed.