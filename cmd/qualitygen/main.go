// Command qualitygen builds the training set for the channel-quality model.
//
// Each scenario is a stream of frames whose conditions change over time (slow
// noise drift, sudden regime shifts, fading, DC drift, noise bursts and
// occasional lost frames). Every frame goes through the Receiver's own DSP
// (dsp.ProcessBPSK) and becomes a ReceiverMetrics message, exactly as the
// live Receiver reports it. Consecutive windows of that stream are summarised
// with shared/quality, the same code the Controller runs.
//
// One CSV row per pair of consecutive windows: the features and measured class
// of window t, and the measured class of window t+1 (the prediction target).
// The data is SIMULATED; ml/README.md explains how to replace it with
// recorded live metrics (controller "metricsLog").
package main

import (
	"encoding/csv"
	"flag"
	"fmt"
	"log"
	"math"
	"math/rand"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"sync"

	controlv1 "github.com/streaming-live-kalman/filter/gen/control/v1"
	"github.com/streaming-live-kalman/filter/shared/dsp"
	"github.com/streaming-live-kalman/filter/shared/quality"
)

type params struct {
	scenarios, window, windows, samplesPerFrame, samplesPerSymbol int
	seed                                                          int64
}

type pair struct {
	scenario, index int
	features        []float32
	current, next   quality.Class
}

func main() {
	out := flag.String("out", "ml/data/quality_dataset.csv", "output CSV path")
	scenarios := flag.Int("scenarios", 2000, "number of simulated streams")
	window := flag.Int("window", 12, "frames per window (Controller windowSize)")
	windows := flag.Int("windows", 30, "windows per stream")
	seed := flag.Int64("seed", 20261112, "base random seed")
	flag.Parse()
	p := params{scenarios: *scenarios, window: *window, windows: *windows, samplesPerFrame: 512, samplesPerSymbol: 8, seed: *seed}

	results := make([][]pair, p.scenarios)
	jobs := make(chan int)
	var wg sync.WaitGroup
	for w := 0; w < runtime.NumCPU(); w++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for i := range jobs {
				results[i] = simulate(p, i)
			}
		}()
	}
	for i := 0; i < p.scenarios; i++ {
		jobs <- i
	}
	close(jobs)
	wg.Wait()

	if err := write(*out, results); err != nil {
		log.Fatal(err)
	}
	counts := map[quality.Class]int{}
	n := 0
	for _, s := range results {
		for _, r := range s {
			counts[r.next]++
			n++
		}
	}
	fmt.Printf("wrote %d window pairs from %d scenarios to %s\n", n, p.scenarios, *out)
	for _, c := range quality.Classes {
		fmt.Printf("  next=%-8s %6d (%.1f%%)\n", c, counts[c], 100*float64(counts[c])/float64(max(n, 1)))
	}
}

func simulate(p params, index int) []pair {
	rng := rand.New(rand.NewSource(p.seed + int64(index)*7919))
	amplitude := math.Exp(uniform(rng, math.Log(0.3), math.Log(2.0)))
	logNoise := uniform(rng, math.Log(0.05), math.Log(2.5))
	noiseWalk := uniform(rng, 0, 0.03) // per-frame random walk of log(noise)
	shiftProb := 0.0
	if rng.Float64() < 0.5 {
		shiftProb = uniform(rng, 0.002, 0.02) // sudden regime changes
	}
	gapProb := 0.0
	if rng.Float64() < 0.3 {
		gapProb = uniform(rng, 0.0005, 0.01)
	}
	withReference := rng.Float64() >= 0.2 // 20% of streams carry no reference bits
	channel := randomChannel(rng, amplitude, p.samplesPerFrame)
	symbols := p.samplesPerFrame / p.samplesPerSymbol
	k := dsp.NewKalman(0.0268, 1) // the rule policy's fixed tracking ratio

	frames := p.window * p.windows
	all := make([]*controlv1.ReceiverMetrics, 0, frames)
	var seq, gaps uint64
	for len(all) < frames {
		seq++
		if rng.Float64() < gapProb { // a lost frame: the receiver sees a jump
			seq++
			gaps++
			k.Reset()
		}
		logNoise += noiseWalk * rng.NormFloat64()
		if rng.Float64() < shiftProb {
			logNoise += math.Log(uniform(rng, 0.4, 3.0))
		}
		logNoise = math.Max(math.Log(0.03), math.Min(math.Log(3.0), logNoise))
		samples, ref := channel.Frame(rng, symbols, p.samplesPerSymbol, float32(amplitude), math.Exp(logNoise))
		if !withReference {
			ref = nil
		}
		m := dsp.ProcessBPSK(k, samples, p.samplesPerSymbol, ref)
		all = append(all, &controlv1.ReceiverMetrics{Sequence: seq, SnrDb: float32(m.SNRDB), NoiseVariance: float32(m.NoiseVariance), ComparedBits: m.Compared, BitErrors: m.Errors, Ber: float32(m.BER), FrameMean: float32(m.FrameMean), DcEstimate: float32(m.DCEstimate), SequenceGaps: gaps})
	}

	var out []pair
	var prev *quality.Window
	for w := 0; w < p.windows; w++ {
		win, err := quality.Summarise(all[w*p.window : (w+1)*p.window])
		if err != nil {
			continue
		}
		if prev != nil {
			out = append(out, pair{scenario: index, index: w - 1, features: prev.Features(), current: prev.MeasuredClass(), next: win.MeasuredClass()})
		}
		prev = &win
	}
	return out
}

// randomChannel mirrors cmd/datagen: about 30% clean AWGN, the rest with
// independent fading, DC drift and/or noise bursts.
func randomChannel(rng *rand.Rand, amplitude float64, samplesPerFrame int) dsp.Channel {
	var c dsp.Channel
	if rng.Float64() < 0.3 {
		return c
	}
	if rng.Float64() < 0.6 {
		c.FadingDepth = uniform(rng, 0.3, 0.95)
		c.FadingPeriodSamples = math.Exp(uniform(rng, math.Log(2), math.Log(60))) * float64(samplesPerFrame)
	}
	if rng.Float64() < 0.5 {
		c.DriftStddev = math.Exp(uniform(rng, math.Log(0.002), math.Log(0.03))) * amplitude
		c.DriftReversion = math.Exp(uniform(rng, math.Log(3e-4), math.Log(1e-2)))
	}
	if rng.Float64() < 0.4 {
		c.BurstProbability = uniform(rng, 0.05, 0.4)
		c.BurstNoiseMultiplier = uniform(rng, 2, 6)
	}
	return c
}

func write(path string, results [][]pair) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()
	w := csv.NewWriter(f)
	header := append([]string{"scenario", "window"}, quality.FeatureNames...)
	header = append(header, "current_class", "next_class")
	if err := w.Write(header); err != nil {
		return err
	}
	for _, s := range results {
		for _, r := range s {
			rec := []string{strconv.Itoa(r.scenario), strconv.Itoa(r.index)}
			for _, v := range r.features {
				rec = append(rec, strconv.FormatFloat(float64(v), 'g', 8, 32))
			}
			rec = append(rec, r.current.String(), r.next.String())
			if err := w.Write(rec); err != nil {
				return err
			}
		}
	}
	w.Flush()
	return w.Error()
}

func uniform(rng *rand.Rand, lo, hi float64) float64 { return lo + rng.Float64()*(hi-lo) }
