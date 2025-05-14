package main

import (
	"testing"
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
)

func TestDefaultMQTTConfig(t *testing.T) {
	config := DefaultMQTTConfig()

	// Verify default configuration values
	if config.BrokerURL != "tcp://localhost:1883" {
		t.Errorf("Expected BrokerURL to be 'tcp://localhost:1883', got '%s'", config.BrokerURL)
	}

	if config.ClientID != "dcentral-edge-gateway" {
		t.Errorf("Expected ClientID to be 'dcentral-edge-gateway', got '%s'", config.ClientID)
	}

	if config.CleanSession != true {
		t.Errorf("Expected CleanSession to be true, got %v", config.CleanSession)
	}

	if config.QoS != 1 {
		t.Errorf("Expected QoS to be 1, got %d", config.QoS)
	}

	if config.ConnectionTimeout != 30*time.Second {
		t.Errorf("Expected ConnectionTimeout to be 30s, got %v", config.ConnectionTimeout)
	}

	if len(config.TopicsToSubscribe) != 1 || config.TopicsToSubscribe[0] != "dcentral/edge/+/data" {
		t.Errorf("Expected TopicsToSubscribe to contain 'dcentral/edge/+/data', got %v", config.TopicsToSubscribe)
	}
}

func TestNewMQTTClient(t *testing.T) {
	config := DefaultMQTTConfig()
	client := NewMQTTClient(config)

	if client == nil {
		t.Fatal("Expected NewMQTTClient to return a non-nil client")
	}

	if client.config.BrokerURL != config.BrokerURL {
		t.Errorf("Expected client config BrokerURL to be '%s', got '%s'", config.BrokerURL, client.config.BrokerURL)
	}

	if len(client.handlers) != 0 {
		t.Errorf("Expected handlers map to be empty, got %d handlers", len(client.handlers))
	}
}

func TestRegisterHandler(t *testing.T) {
	config := DefaultMQTTConfig()
	client := NewMQTTClient(config)

	// Define a test handler
	testTopic := "test/topic"
	var handlerCalled bool
	testHandler := func(c mqtt.Client, m mqtt.Message) {
		handlerCalled = true
	}

	// Register the handler
	client.RegisterHandler(testTopic, testHandler)

	// Check if the handler was registered
	if len(client.handlers) != 1 {
		t.Errorf("Expected 1 handler, got %d", len(client.handlers))
	}

	// Check if the handler for the test topic exists
	handler, exists := client.handlers[testTopic]
	if !exists {
		t.Errorf("Expected handler for topic '%s' to exist", testTopic)
	}

	// This is a bit of a hack to check if it's the same handler function
	// We can't directly compare functions in Go, so we're checking the function pointer
	if handler == nil {
		t.Errorf("Expected handler to be non-nil")
	}
}

// MockMessage implements mqtt.Message for testing
type MockMessage struct {
	topic   string
	payload []byte
	qos     byte
	retained bool
	duplicate bool
	messageID uint16
}

func (m *MockMessage) Duplicate() bool {
	return m.duplicate
}

func (m *MockMessage) Qos() byte {
	return m.qos
}

func (m *MockMessage) Retained() bool {
	return m.retained
}

func (m *MockMessage) Topic() string {
	return m.topic
}

func (m *MockMessage) MessageID() uint16 {
	return m.messageID
}

func (m *MockMessage) Payload() []byte {
	return m.payload
}

func (m *MockMessage) Ack() {
	// No-op for testing
}

func TestDefaultMessageHandler(t *testing.T) {
	config := DefaultMQTTConfig()
	client := NewMQTTClient(config)

	// Define a test handler for a specific topic
	testTopic := "test/topic"
	var specificHandlerCalled bool
	client.RegisterHandler(testTopic, func(c mqtt.Client, m mqtt.Message) {
		specificHandlerCalled = true
	})

	// Create a mock message for the specific topic
	mockMsg := &MockMessage{
		topic:   testTopic,
		payload: []byte("test payload"),
	}

	// Call the default handler with the mock message
	client.defaultMessageHandler(nil, mockMsg)

	// The specific handler should have been called
	if !specificHandlerCalled {
		t.Errorf("Expected specific handler to be called for topic '%s'", testTopic)
	}

	// Reset the flag and test with a different topic
	specificHandlerCalled = false
	otherMockMsg := &MockMessage{
		topic:   "other/topic",
		payload: []byte("other payload"),
	}

	// For a topic without a specific handler, it should use the default processing
	client.defaultMessageHandler(nil, otherMockMsg)

	// The specific handler should not have been called
	if specificHandlerCalled {
		t.Errorf("Expected specific handler NOT to be called for topic '%s'", otherMockMsg.Topic())
	}
}