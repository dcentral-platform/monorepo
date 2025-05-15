import { check, sleep } from 'k6';
import mqtt from 'k6/x/mqtt';

// Test configuration
export const options = {
  stages: [
    { duration: '30s', target: 100 }, // Ramp up to 100 clients
    { duration: '1m', target: 100 },  // Stay at 100 clients
    { duration: '30s', target: 0 },   // Ramp down
  ],
  thresholds: {
    'mqtt_published': ['p(95)<100'],  // 95% of publishes complete within 100ms
    'mqtt_received': ['p(95)<200'],   // 95% of messages received within 200ms
    'mqtt_errors': ['count<5'],       // Less than 5 errors
    'mqtt_loss_percentage': ['value<0.5'], // Less than 0.5% message loss
  },
};

// Message loss metric
const messageLoss = new k6.Metric('mqtt_loss_percentage', 'gauge');

// Unique client ID prefix
const CLIENT_PREFIX = 'dcentral-k6-';

// Counter for messages sent and received
let sentMessages = 0;
let receivedMessages = 0;

// MQTT broker URL
const MQTT_BROKER = __ENV.MQTT_BROKER || 'tcp://localhost:1883';

// Topics
const SENSOR_TOPIC = 'dcentral/edge/+/data';
const COMMAND_TOPIC = 'dcentral/edge/commands';
const STATUS_TOPIC = 'dcentral/edge/status';

// Generate a random device ID
function getRandomDeviceId() {
  return `device-${Math.floor(Math.random() * 10000)}`;
}

// Generate a random sensor reading payload
function generateSensorPayload(deviceId) {
  return JSON.stringify({
    device_id: deviceId,
    timestamp: new Date().toISOString(),
    readings: {
      temperature: Math.random() * 30 + 10,  // 10-40°C
      humidity: Math.random() * 50 + 30,     // 30-80%
      battery: Math.random() * 20 + 80,      // 80-100%
    },
    status: 'active',
  });
}

// Default function - run for each VU
export default function() {
  const deviceId = getRandomDeviceId();
  const clientId = `${CLIENT_PREFIX}${deviceId}`;
  
  // Create client
  const client = mqtt.Client();
  
  // Connect to broker
  client.connect(MQTT_BROKER, {
    clientId: clientId,
    clean_session: true,
  });
  
  // Subscribe to device topic
  const deviceTopic = `dcentral/edge/${deviceId}/data`;
  client.subscribe(deviceTopic, 1);
  
  // Also subscribe to command topic
  client.subscribe(COMMAND_TOPIC, 1);
  
  // Publish loop
  for (let i = 0; i < 10; i++) {
    const payload = generateSensorPayload(deviceId);
    
    const startTime = new Date();
    client.publish(deviceTopic, payload, 1, false);
    const endTime = new Date();
    
    const publishTime = endTime - startTime;
    mqtt.metric_published.add(publishTime);
    
    sentMessages++;
    
    // Try to receive message
    const msg = client.receive(100); // Wait up to 100ms for message
    if (msg) {
      receivedMessages++;
      mqtt.metric_received.add(msg.receiveTime - startTime);
      
      check(msg, {
        'topic matches': (m) => m.topic === deviceTopic || m.topic === COMMAND_TOPIC,
        'payload not empty': (m) => m.payload.length > 0,
      });
    }
    
    // Publish a status update
    if (i === 5) {
      const statusPayload = JSON.stringify({
        device_id: deviceId,
        status: 'online',
        timestamp: new Date().toISOString(),
      });
      client.publish(STATUS_TOPIC, statusPayload, 1, false);
      sentMessages++;
    }
    
    sleep(Math.random() * 0.5 + 0.1); // Sleep 0.1-0.6s between messages
  }
  
  // Wait a bit for final messages
  sleep(1);
  
  // Disconnect
  client.disconnect();
  
  // Calculate message loss
  const loss = sentMessages > 0 ? 
    ((sentMessages - receivedMessages) / sentMessages) * 100 : 0;
  
  messageLoss.add(loss);
}

// Setup function - runs once per test
export function setup() {
  console.log(`Starting MQTT load test targeting ${MQTT_BROKER}`);
  
  // Create a monitoring client
  const monitorClient = mqtt.Client();
  monitorClient.connect(MQTT_BROKER, {
    clientId: 'dcentral-k6-monitor',
    clean_session: true,
  });
  
  // Subscribe to all data topics
  monitorClient.subscribe(SENSOR_TOPIC, 1);
  
  // Disconnect monitoring client
  monitorClient.disconnect();
  
  // Reset counters
  sentMessages = 0;
  receivedMessages = 0;
}

// Teardown function - runs once per test
export function teardown() {
  console.log(`MQTT load test completed:`);
  console.log(`- Messages sent: ${sentMessages}`);
  console.log(`- Messages received: ${receivedMessages}`);
  
  const lossPercentage = sentMessages > 0 ? 
    ((sentMessages - receivedMessages) / sentMessages) * 100 : 0;
  
  console.log(`- Message loss: ${lossPercentage.toFixed(2)}%`);
  
  if (lossPercentage > 0.5) {
    console.error(`WARNING: Message loss exceeds 0.5% threshold!`);
  } else {
    console.log(`✓ Message loss below 0.5% threshold`);
  }
}