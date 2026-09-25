package config

import (
	"encoding/json"
	"fmt"
	"os"
)

type TX struct {
	Listen           string  `json:"listen"`
	Receiver         string  `json:"receiver"`
	RunID            string  `json:"runId"`
	SampleRateHz     uint32  `json:"sampleRateHz"`
	SamplesPerSymbol uint32  `json:"samplesPerSymbol"`
	SamplesPerFrame  int     `json:"samplesPerFrame"`
	Amplitude        float32 `json:"amplitude"`
	NoiseStdDev      float64 `json:"noiseStdDev"`
	Seed             int64   `json:"seed"`
}

type RX struct {
	Listen        string  `json:"listen"`
	HTTPListen    string  `json:"httpListen"`
	Controller    string  `json:"controller"`
	QueueCapacity int     `json:"queueCapacity"`
	KalmanQ       float32 `json:"kalmanQ"`
	KalmanR       float32 `json:"kalmanR"`
}

type Controller struct {
	Listen                 string  `json:"listen"`
	HTTPListen             string  `json:"httpListen"`
	WindowSize             int     `json:"windowSize"`
	DecisionCooldownFrames uint64  `json:"decisionCooldownFrames"`
	MinKalmanR             float32 `json:"minKalmanR"`
	MaxKalmanR             float32 `json:"maxKalmanR"`
}

type All struct {
	TX         TX         `json:"tx"`
	RX         RX         `json:"rx"`
	Controller Controller `json:"controller"`
}

func Load(path string) (All, error) {
	var c All
	b, err := os.ReadFile(path)
	if err != nil {
		return c, err
	}
	if err := json.Unmarshal(b, &c); err != nil {
		return c, err
	}
	if c.TX.SamplesPerFrame <= 0 || c.TX.SamplesPerSymbol == 0 {
		return c, fmt.Errorf("invalid TX frame dimensions")
	}
	if c.RX.QueueCapacity <= 0 || c.Controller.WindowSize <= 0 {
		return c, fmt.Errorf("queueCapacity and windowSize must be positive")
	}
	return c, nil
}
