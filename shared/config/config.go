package config

import (
	"encoding/json"
	"fmt"
	"math"
	"os"
)

type Sender struct {
	Listen           string  `json:"listen"`
	HTTPListen       string  `json:"httpListen"` // optional file-transfer API
	Receiver         string  `json:"receiver"`
	RunID            string  `json:"runId"`
	SampleRateHz     uint32  `json:"sampleRateHz"`
	SamplesPerSymbol uint32  `json:"samplesPerSymbol"`
	SamplesPerFrame  int     `json:"samplesPerFrame"`
	Amplitude        float32 `json:"amplitude"`
	NoiseStdDev      float64 `json:"noiseStdDev"`
	Seed             int64   `json:"seed"`
	// Optional simulated channel impairments (all zero = ideal AWGN). See
	// dsp.Channel; the fading period is expressed in frames here.
	FadingDepth          float64 `json:"fadingDepth"`
	FadingPeriodFrames   float64 `json:"fadingPeriodFrames"`
	DriftStddev          float64 `json:"driftStddev"`
	DriftReversion       float64 `json:"driftReversion"`
	BurstProbability     float64 `json:"burstProbability"`
	BurstNoiseMultiplier float64 `json:"burstNoiseMultiplier"`
}

type Receiver struct {
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
	// Policy selects the adaptation policy: "rule" (default) or "onnx".
	Policy string `json:"policy"`
	// OnnxModel is the model path used when Policy is "onnx".
	OnnxModel string `json:"onnxModel"`
}

type All struct {
	Sender     Sender     `json:"sender"`
	Receiver   Receiver   `json:"receiver"`
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
	if c.Sender.SamplesPerFrame <= 0 || c.Sender.SamplesPerSymbol == 0 {
		return c, fmt.Errorf("invalid sender frame dimensions")
	}
	if c.Receiver.QueueCapacity <= 0 || c.Controller.WindowSize <= 0 {
		return c, fmt.Errorf("queueCapacity and windowSize must be positive")
	}
	if !finitePositive(c.Receiver.KalmanQ) || !finitePositive(c.Receiver.KalmanR) {
		return c, fmt.Errorf("receiver kalmanQ and kalmanR must be finite positive values")
	}
	if !finitePositive(c.Controller.MinKalmanR) || !finitePositive(c.Controller.MaxKalmanR) || c.Controller.MinKalmanR > c.Controller.MaxKalmanR {
		return c, fmt.Errorf("controller Kalman R bounds must be finite positive values with min <= max")
	}
	s := c.Sender
	if s.FadingDepth < 0 || s.FadingDepth >= 1 || s.FadingPeriodFrames < 0 || s.DriftStddev < 0 || s.DriftReversion < 0 || s.DriftReversion > 1 || s.BurstProbability < 0 || s.BurstProbability > 1 || s.BurstNoiseMultiplier < 0 {
		return c, fmt.Errorf("sender channel impairments out of range (fadingDepth in [0,1), probabilities and reversion in [0,1], others >= 0)")
	}
	if s.FadingDepth > 0 && s.FadingPeriodFrames == 0 {
		return c, fmt.Errorf("sender fadingPeriodFrames must be positive when fadingDepth is set")
	}
	switch c.Controller.Policy {
	case "":
		c.Controller.Policy = "rule"
	case "rule":
	case "onnx":
		if c.Controller.OnnxModel == "" {
			return c, fmt.Errorf("controller onnxModel is required when policy is onnx")
		}
	default:
		return c, fmt.Errorf("unknown controller policy %q (want rule or onnx)", c.Controller.Policy)
	}
	return c, nil
}

func finitePositive(value float32) bool {
	return value > 0 && !math.IsNaN(float64(value)) && !math.IsInf(float64(value), 0)
}
