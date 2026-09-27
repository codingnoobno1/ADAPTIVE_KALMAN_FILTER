package config

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

const validConfig = `{
  "sender":{"sampleRateHz":48000,"samplesPerSymbol":8,"samplesPerFrame":512},
  "receiver":{"queueCapacity":4,"kalmanQ":0.2,"kalmanR":0.5},
  "controller":{"windowSize":4,"minKalmanR":0.02,"maxKalmanR":4.0}
}`

func TestLoadRejectsInvalidReceiverKalmanValues(t *testing.T) {
	tests := []struct{ old, replacement string }{
		{"\"kalmanQ\":0.2", "\"kalmanQ\":0"},
		{"\"kalmanR\":0.5", "\"kalmanR\":-1"},
	}
	for _, tt := range tests {
		path := filepath.Join(t.TempDir(), "config.json")
		content := strings.Replace(validConfig, tt.old, tt.replacement, 1)
		if err := os.WriteFile(path, []byte(content), 0o600); err != nil {
			t.Fatal(err)
		}
		if _, err := Load(path); err == nil || !strings.Contains(err.Error(), "kalmanQ and kalmanR") {
			t.Fatalf("Load() error = %v, want receiver Kalman validation error", err)
		}
	}
}

func TestLoadRejectsInvertedControllerBounds(t *testing.T) {
	path := filepath.Join(t.TempDir(), "config.json")
	content := strings.Replace(validConfig, "\"maxKalmanR\":4.0", "\"maxKalmanR\":0.01", 1)
	if err := os.WriteFile(path, []byte(content), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := Load(path); err == nil || !strings.Contains(err.Error(), "bounds") {
		t.Fatalf("Load() error = %v, want controller bound validation error", err)
	}
}
