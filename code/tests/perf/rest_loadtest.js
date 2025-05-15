import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Rate, Trend } from 'k6/metrics';

// Configuration
const API_BASE = __ENV.API_BASE || 'http://localhost:8080';

// Custom metrics
const errorRate = new Rate('error_rate');
const apiCalls = new Counter('api_calls');
const ttfb = new Trend('time_to_first_byte');

// Test configuration
export const options = {
  stages: [
    { duration: '30s', target: 50 },    // Ramp up
    { duration: '1m', target: 100 },    // Ramp up more
    { duration: '3m', target: 500 },    // Load test with 500 VUs
    { duration: '1m', target: 100 },    // Ramp down
    { duration: '30s', target: 0 },     // Ramp down to zero
  ],
  thresholds: {
    http_req_duration: ['p(95)<200'], // 95% of requests must complete within 200ms
    error_rate: ['rate<0.01'],        // Error rate must be less than 1%
    'http_req_duration{endpoint:health}': ['p(95)<50'],  // Health check must be fast
    'http_req_duration{endpoint:data}': ['p(95)<150'],   // Data endpoint threshold
    'http_req_duration{endpoint:status}': ['p(95)<100'], // Status endpoint threshold
  },
};

// Endpoints to test
const endpoints = [
  { name: 'health', path: '/v1/health', weight: 0.2 },
  { name: 'status', path: '/v1/status', weight: 0.3 },
  { name: 'data', path: '/v1/data', weight: 0.5 },
];

// Choose a random endpoint based on weights
function chooseEndpoint() {
  const random = Math.random();
  let cumulativeWeight = 0;
  
  for (const endpoint of endpoints) {
    cumulativeWeight += endpoint.weight;
    if (random <= cumulativeWeight) {
      return endpoint;
    }
  }
  
  return endpoints[0]; // Fallback
}

// Main test function - executed by each VU
export default function() {
  // Choose which endpoint to call
  const endpoint = chooseEndpoint();
  
  // Tag to separate metrics by endpoint
  const tags = { endpoint: endpoint.name };
  
  // Make the request
  const start = new Date();
  const res = http.get(`${API_BASE}${endpoint.path}`, { tags });
  
  // Track time to first byte
  ttfb.add(res.timings.waiting, tags);
  
  // Count the call
  apiCalls.add(1, tags);
  
  // Check if the request was successful
  const success = check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
    'has valid content-type': (r) => r.headers['Content-Type'] && 
      (r.headers['Content-Type'].includes('application/json') || 
       r.headers['Content-Type'].includes('text/plain')),
  }, tags);
  
  // Record errors
  errorRate.add(!success, tags);
  
  // Log errors for debugging
  if (!success) {
    console.error(`Request to ${endpoint.path} failed: ${res.status} ${res.body}`);
  }
  
  // Add random sleep to simulate user behavior
  sleep(Math.random() * 1 + 0.5); // Sleep between 0.5-1.5s
}

// Setup function - runs once per test
export function setup() {
  console.log(`Starting load test against ${API_BASE}`);
  
  // Check if the API is reachable
  const res = http.get(`${API_BASE}/v1/health`);
  if (res.status !== 200) {
    throw new Error(`API health check failed: ${res.status} ${res.body}`);
  }
  
  console.log('API health check passed, starting test');
}

// Teardown function - runs once per test
export function teardown() {
  console.log('Load test completed');
}