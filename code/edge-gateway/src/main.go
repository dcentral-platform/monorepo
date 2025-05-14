package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

// Config holds the application configuration
type Config struct {
	Port            int    `json:"port"`
	LogLevel        string `json:"logLevel"`
	UpstreamService string `json:"upstreamService"`
	TLSEnabled      bool   `json:"tlsEnabled"`
	CertFile        string `json:"certFile"`
	KeyFile         string `json:"keyFile"`
}

// HealthResponse represents the health check response
type HealthResponse struct {
	Status    string    `json:"status"`
	Timestamp time.Time `json:"timestamp"`
	Version   string    `json:"version"`
}

// AppContext holds application context and dependencies
type AppContext struct {
	Config     Config
	Logger     *log.Logger
	HttpClient *http.Client
}

// Global variables
var (
	appContext AppContext
	version    = "0.1.0"
)

func loadConfig() Config {
	// TODO: Implement actual config loading from file or environment
	return Config{
		Port:            8080,
		LogLevel:        "info",
		UpstreamService: "http://localhost:9000",
		TLSEnabled:      false,
		CertFile:        "cert.pem",
		KeyFile:         "key.pem",
	}
}

func setupRoutes(appCtx *AppContext) *http.ServeMux {
	mux := http.NewServeMux()

	// Health check endpoint
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		response := HealthResponse{
			Status:    "up",
			Timestamp: time.Now(),
			Version:   version,
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)
	})

	// API proxy endpoint
	mux.HandleFunc("/api/", func(w http.ResponseWriter, r *http.Request) {
		// TODO: Implement actual API proxy logic
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"message": "API proxy placeholder"}`))
	})

	// Default route
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/" {
			http.NotFound(w, r)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"message": "DCentral Edge Gateway"}`))
	})

	return mux
}

func main() {
	// Initialize logger
	logger := log.New(os.Stdout, "EDGE-GATEWAY: ", log.LstdFlags|log.Lshortfile)
	
	// Load configuration
	config := loadConfig()
	
	// Setup application context
	appContext = AppContext{
		Config: config,
		Logger: logger,
		HttpClient: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
	
	// Setup HTTP routes
	mux := setupRoutes(&appContext)
	
	// Create server
	server := &http.Server{
		Addr:    fmt.Sprintf(":%d", config.Port),
		Handler: mux,
	}
	
	// Channel to listen for interrupt signals
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)
	
	// Start server in a goroutine
	go func() {
		logger.Printf("Starting server on port %d", config.Port)
		var err error
		
		if config.TLSEnabled {
			err = server.ListenAndServeTLS(config.CertFile, config.KeyFile)
		} else {
			err = server.ListenAndServe()
		}
		
		if err != nil && err != http.ErrServerClosed {
			logger.Fatalf("Error starting server: %v", err)
		}
	}()
	
	// Wait for interrupt signal
	<-stop
	logger.Println("Server is shutting down...")
	
	// TODO: Implement graceful shutdown with proper context timeout
	logger.Println("Server stopped")
}