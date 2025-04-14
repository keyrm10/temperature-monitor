package main

import (
	"encoding/json"
	"fmt"
	"log"
	"math"
	"net/http"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

const (
	baseURL        = "https://api.open-meteo.com/v1/forecast"
	updateInterval = 15 * time.Minute // Open-Meteo API updates current temperature every 900 seconds (15 minutes)
	requestTimeout = 10 * time.Second // timeout for each API request
	addr           = ":8080"
)

type Coordinates struct {
	Location  string
	Latitude  float64
	Longitude float64
}

var coordinates = Coordinates{
	Location:  "Tallinn", // default location
	Latitude:  59.43696,
	Longitude: 24.75353,
}

// maps JSON structure returned by the API. `current` field contains nested properties: `time` and `temperature_2m`
type APIResponse struct {
	Current struct {
		Time        string  `json:"time"`
		Temperature float64 `json:"temperature_2m"`
	} `json:"current"`
}

var temperatureGauge = prometheus.NewGaugeVec(
	prometheus.GaugeOpts{
		Name: "current_temperature_celsius",
		Help: "Current temperature in degrees Celsius",
	},
	[]string{"location"}, // label to differentiate temperatures by location
)

func init() {
	prometheus.MustRegister(temperatureGauge)
	temperatureGauge.WithLabelValues(coordinates.Location).Set(math.NaN()) // set initial value to NaN until first update
}

func buildURL() string {
	return fmt.Sprintf("%s?latitude=%f&longitude=%f&current=temperature_2m", baseURL, coordinates.Latitude, coordinates.Longitude)
}

var httpClient = &http.Client{Timeout: requestTimeout} // custom HTTP client with built-in timeout

func fetchTemperature() (*APIResponse, error) {
	resp, err := httpClient.Get(buildURL())
	if err != nil {
		return nil, fmt.Errorf("request error: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}

	var data APIResponse
	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		return nil, fmt.Errorf("failed to decode JSON: %w", err)
	}

	return &data, nil
}

func updateTemperature() {
	data, err := fetchTemperature()
	if err != nil {
		log.Printf("error updating temperature: %v", err)
		return
	}
	temperatureGauge.WithLabelValues(coordinates.Location).Set(data.Current.Temperature)
	log.Printf("updated temperature for %s: %.1f °C at %s", coordinates.Location, data.Current.Temperature, data.Current.Time)
}

func startTemperatureUpdater() {
	// start a goroutine to update temperature every 15 minutes
	ticker := time.NewTicker(updateInterval)
	defer ticker.Stop()

	updateTemperature()

	for range ticker.C {
		updateTemperature()
	}
}

func main() {
	go startTemperatureUpdater()

	http.Handle("/metrics", promhttp.Handler())
	log.Printf("starting Prometheus exporter on %s/metrics", addr)
	log.Fatal(http.ListenAndServe(addr, nil))
}
