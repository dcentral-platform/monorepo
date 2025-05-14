import { check, sleep } from 'k6';
import mqtt from 'k6/x/mqtt';

// Test configuration
export const options = {
  vus: 10,           // Number of virtual users (simulated devices)
  duration: '30s',   // Test duration
  thresholds: {
    'mqtt_publish': ['p(95)<250'],  // 95% of publish operations should complete within 250ms
    'mqtt_receive': ['p(95)<500'],  // 95% of message receipts should complete within 500ms
    'mqtt_errors': ['count<5'],     // Less than 5 MQTT errors during the test
  },
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)', 'count'],
};

// Configuration variables
const MQTT_BROKER = __ENV.MQTT_BROKER || 'tcp://localhost:1883';
const CLIENT_PREFIX = 'k6-client-';
const EDGE_TOPIC = 'dcentral/edge/%s/data';
const STATUS_TOPIC = 'dcentral/edge/status';
const COMMAND_TOPIC = 'dcentral/edge/commands';

// Utility function to generate a random device ID
function getRandomDeviceId() {
  return `device-${Math.floor(Math.random() * 10000)}`;
}

// Utility function to generate a random payload
function getRandomPayload(deviceId) {
  return JSON.stringify({
    device_id: deviceId,
    timestamp: new Date().toISOString(),
    sensor_readings: {
      temperature: Math.random() * 30 + 10,  // 10-40°C
      humidity: Math.random() * 50 + 30,     // 30-80%
      battery: Math.random() * 20 + 80,      // 80-100%
    },
    status: 'active',
  });
}

// Setup function (runs once per VU)
export function setup() {
  console.log(`Performance test starting with ${options.vus} simulated devices`);
  
  // Initialize the command client to monitor responses
  const commandClient = mqtt.Client();
  const commandClientId = `${CLIENT_PREFIX}command-listener`;
  
  commandClient.connect(MQTT_BROKER, {
    clientId: commandClientId,
    clean_session: true,
  });
  
  commandClient.subscribe(COMMAND_TOPIC, 0);
  
  return {
    commandClient,
    commandClientId,
  };
}

// Default function (runs for each VU)
export default function(data) {
  // Create a unique device ID for this VU
  const deviceId = getRandomDeviceId();
  const topic = EDGE_TOPIC.replace('%s', deviceId);
  
  // Create a client for this simulated device
  const client = mqtt.Client();
  const clientId = `${CLIENT_PREFIX}${deviceId}`;
  
  // Connect the client
  client.connect(MQTT_BROKER, {
    clientId,
    clean_session: true,
  });
  
  // Subscribe to device-specific topics
  client.subscribe(topic, 1);
  
  // Publish device data messages in a loop
  for (let i = 0; i < 5; i++) {
    const payload = getRandomPayload(deviceId);
    
    const startTime = new Date();
    client.publish(topic, payload, 1, false);
    const duration = new Date() - startTime;
    
    check(duration, {
      'publish time < 250ms': (d) => d < 250,
    });
    
    // Add to custom metrics
    mqtt.metric_publish_time.add(duration);
    
    // Sleep between publishes to simulate realistic device behavior
    sleep(Math.random() * 2 + 1); // 1-3 seconds
  }
  
  // Publish a status message
  const statusPayload = JSON.stringify({
    device_id: deviceId,
    status: 'online',
    timestamp: new Date().toISOString(),
  });
  
  client.publish(STATUS_TOPIC, statusPayload, 1, false);
  
  // Clean up - disconnect the client
  client.disconnect();
}

// Teardown function (runs once per test)
export function teardown(data) {
  if (data.commandClient) {
    data.commandClient.disconnect();
  }
  
  console.log('Performance test completed');
}