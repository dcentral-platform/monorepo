package main

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"io/ioutil"
	"sync"
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
	log "github.com/sirupsen/logrus"
)

// MQTTConfig holds the configuration for the MQTT client
type MQTTConfig struct {
	BrokerURL          string
	ClientID           string
	Username           string
	Password           string
	CleanSession       bool
	QoS                byte
	ConnectionTimeout  time.Duration
	KeepAlive          time.Duration
	PingTimeout        time.Duration
	ConnectRetryDelay  time.Duration
	MaxReconnectAttempt int
	CACertPath         string
	ClientCertPath     string
	ClientKeyPath      string
	TopicsToSubscribe  []string
}

// DefaultMQTTConfig returns a default MQTT configuration
func DefaultMQTTConfig() MQTTConfig {
	return MQTTConfig{
		BrokerURL:          "tcp://localhost:1883",
		ClientID:           "dcentral-edge-gateway",
		CleanSession:       true,
		QoS:                1,
		ConnectionTimeout:  30 * time.Second,
		KeepAlive:          60 * time.Second,
		PingTimeout:        10 * time.Second,
		ConnectRetryDelay:  5 * time.Second,
		MaxReconnectAttempt: 10,
		TopicsToSubscribe:  []string{"dcentral/edge/+/data"},
	}
}

// MQTTClient wraps the MQTT client functionality
type MQTTClient struct {
	config    MQTTConfig
	client    mqtt.Client
	handlers  map[string]mqtt.MessageHandler
	handlerMu sync.RWMutex
}

// NewMQTTClient creates a new MQTT client with the given configuration
func NewMQTTClient(config MQTTConfig) *MQTTClient {
	return &MQTTClient{
		config:   config,
		handlers: make(map[string]mqtt.MessageHandler),
	}
}

// Connect connects to the MQTT broker
func (m *MQTTClient) Connect() error {
	opts := mqtt.NewClientOptions().
		AddBroker(m.config.BrokerURL).
		SetClientID(m.config.ClientID).
		SetCleanSession(m.config.CleanSession).
		SetKeepAlive(m.config.KeepAlive).
		SetPingTimeout(m.config.PingTimeout).
		SetConnectTimeout(m.config.ConnectionTimeout)

	// Set credentials if provided
	if m.config.Username != "" {
		opts.SetUsername(m.config.Username)
		opts.SetPassword(m.config.Password)
	}

	// Set up TLS if certificate paths are provided
	if m.config.CACertPath != "" {
		tlsConfig, err := m.newTLSConfig()
		if err != nil {
			return fmt.Errorf("failed to create TLS config: %w", err)
		}
		opts.SetTLSConfig(tlsConfig)
	}

	// Set the default message handler
	opts.SetDefaultPublishHandler(m.defaultMessageHandler)

	// Set connect and disconnect handlers for logging
	opts.SetOnConnectHandler(func(client mqtt.Client) {
		log.Info("Connected to MQTT broker")
		m.subscribeToTopics()
	})

	opts.SetConnectionLostHandler(func(client mqtt.Client, err error) {
		log.WithError(err).Error("Lost connection to MQTT broker")
	})

	// Set reconnect parameters
	opts.SetAutoReconnect(true)
	opts.SetMaxReconnectInterval(m.config.ConnectRetryDelay)
	opts.SetConnectRetry(true)
	opts.SetMaxReconnectInterval(m.config.ConnectRetryDelay * time.Duration(m.config.MaxReconnectAttempt))

	// Create and connect the client
	m.client = mqtt.NewClient(opts)
	token := m.client.Connect()
	if token.Wait() && token.Error() != nil {
		return fmt.Errorf("failed to connect to MQTT broker: %w", token.Error())
	}

	return nil
}

// newTLSConfig creates a new TLS configuration for MQTT
func (m *MQTTClient) newTLSConfig() (*tls.Config, error) {
	certpool := x509.NewCertPool()
	if m.config.CACertPath != "" {
		cas, err := ioutil.ReadFile(m.config.CACertPath)
		if err != nil {
			return nil, fmt.Errorf("failed to read CA certificate: %w", err)
		}
		certpool.AppendCertsFromPEM(cas)
	}

	// Import client certificate/key pair if paths are provided
	var certificates []tls.Certificate
	if m.config.ClientCertPath != "" && m.config.ClientKeyPath != "" {
		cert, err := tls.LoadX509KeyPair(m.config.ClientCertPath, m.config.ClientKeyPath)
		if err != nil {
			return nil, fmt.Errorf("failed to load client certificate/key pair: %w", err)
		}
		certificates = append(certificates, cert)
	}

	// Create tls.Config with desired TLS properties
	return &tls.Config{
		RootCAs:            certpool,
		ClientAuth:         tls.RequireAndVerifyClientCert,
		ClientCAs:          certpool,
		Certificates:       certificates,
		InsecureSkipVerify: false,
	}, nil
}

// defaultMessageHandler handles messages for topics without a specific handler
func (m *MQTTClient) defaultMessageHandler(client mqtt.Client, msg mqtt.Message) {
	log.WithFields(log.Fields{
		"topic":   msg.Topic(),
		"payload": string(msg.Payload()),
	}).Debug("Received message on topic")

	// Check if there's a specific handler for this topic
	m.handlerMu.RLock()
	handler, exists := m.handlers[msg.Topic()]
	m.handlerMu.RUnlock()

	if exists {
		handler(client, msg)
	} else {
		// Process the message with the default handler
		log.WithField("topic", msg.Topic()).Info("Processing message with default handler")
		ProcessEvent(string(msg.Payload()))
	}
}

// RegisterHandler registers a handler for a specific topic
func (m *MQTTClient) RegisterHandler(topic string, handler mqtt.MessageHandler) {
	m.handlerMu.Lock()
	defer m.handlerMu.Unlock()
	m.handlers[topic] = handler
}

// subscribeToTopics subscribes to all configured topics
func (m *MQTTClient) subscribeToTopics() {
	for _, topic := range m.config.TopicsToSubscribe {
		token := m.client.Subscribe(topic, m.config.QoS, nil)
		token.Wait()
		if token.Error() != nil {
			log.WithFields(log.Fields{
				"topic": topic,
				"error": token.Error(),
			}).Error("Failed to subscribe to topic")
		} else {
			log.WithField("topic", topic).Info("Subscribed to topic")
		}
	}
}

// Publish publishes a message to a topic
func (m *MQTTClient) Publish(topic string, payload interface{}) error {
	if !m.client.IsConnected() {
		return fmt.Errorf("not connected to MQTT broker")
	}

	var payloadStr string
	switch p := payload.(type) {
	case string:
		payloadStr = p
	case []byte:
		payloadStr = string(p)
	default:
		payloadStr = fmt.Sprintf("%v", p)
	}

	token := m.client.Publish(topic, m.config.QoS, false, payloadStr)
	token.Wait()
	if token.Error() != nil {
		return fmt.Errorf("failed to publish message: %w", token.Error())
	}

	log.WithFields(log.Fields{
		"topic":   topic,
		"payload": payloadStr,
	}).Debug("Published message")
	return nil
}

// Disconnect disconnects from the MQTT broker
func (m *MQTTClient) Disconnect() {
	if m.client.IsConnected() {
		m.client.Disconnect(250)
		log.Info("Disconnected from MQTT broker")
	}
}