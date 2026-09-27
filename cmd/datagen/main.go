// Command datagen builds the offline training set for the Controller's ML
// adaptation policy. It uses the Sender's channel simulation (dsp.Channel) and
// the Receiver's demodulator (dsp.ProcessBPSK) directly, so features and labels
// come from exactly the code that runs live.
//
// The Receiver's Kalman filter tracks the channel's DC drift; only the ratio
// rho = Q/R sets how fast it follows. For every simulated channel this tool
// records the features the Controller receives (a window of per-frame SNR,
// noise-variance and frame-mean metrics) and scores every rho on a fixed grid.
// The label is the rho with the lowest BER; the DC-tracking error against the
// channel's true offset breaks ties. Per-rho BER columns are kept so the model
// is evaluated in BER terms, not only regression error.
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

	"github.com/streaming-live-kalman/filter/shared/dsp"
)

// Features are the Controller's window statistics, in model-input order.
var featureNames = []string{"snr_db_mean", "snr_db_std", "noise_var_mean", "noise_var_std", "frame_mean_std", "frame_mean_step"}

type params struct {
	scenarios, windowFrames, scoreFrames, samplesPerFrame, samplesPerSymbol int
	grid                                                                    []float64
	seed                                                                    int64
}

type row struct {
	amplitude, noise float64
	channel          dsp.Channel
	features         []float64
	bestRho, dcRMSE  float64
	bers             []float64
}

func main() {
	out := flag.String("out", "ml/data/dataset.csv", "output CSV path")
	scenarios := flag.Int("scenarios", 6000, "number of simulated channel conditions")
	window := flag.Int("window", 12, "frames per feature window (Controller windowSize)")
	score := flag.Int("score-frames", 200, "frames used to score each candidate rho")
	seed := flag.Int64("seed", 20260927, "base random seed")
	flag.Parse()

	p := params{scenarios: *scenarios, windowFrames: *window, scoreFrames: *score, samplesPerFrame: 512, samplesPerSymbol: 8, seed: *seed}
	// Log-spaced rho = Q/R candidates (per 8-symbol DC measurement) from "hold a
	// constant offset" (1e-7) to "follow very fast drift" (10).
	for i := 0; i < 29; i++ {
		p.grid = append(p.grid, math.Pow(10, -7+8*float64(i)/28))
	}

	rows := make([]row, p.scenarios)
	jobs := make(chan int)
	var wg sync.WaitGroup
	for w := 0; w < runtime.NumCPU(); w++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for i := range jobs {
				rows[i] = simulate(p, i)
			}
		}()
	}
	for i := 0; i < p.scenarios; i++ {
		jobs <- i
	}
	close(jobs)
	wg.Wait()

	if err := write(*out, p, rows); err != nil {
		log.Fatal(err)
	}
	fmt.Printf("wrote %d scenarios x %d rho candidates to %s\n", len(rows), len(p.grid), *out)
}

func simulate(p params, index int) row {
	rng := rand.New(rand.NewSource(p.seed + int64(index)))
	// Sample the channel log-uniformly so low and high SNR are both covered.
	amplitude := math.Exp(uniform(rng, math.Log(0.3), math.Log(2.0)))
	noise := math.Exp(uniform(rng, math.Log(0.05), math.Log(3.0)))
	symbols := p.samplesPerFrame / p.samplesPerSymbol
	channel := randomChannel(rng, amplitude, p.samplesPerFrame)
	settings := channel // impairment settings before any state accumulates

	// One shared frame sequence per scenario: every candidate sees exactly the
	// same noise (common random numbers), so the comparison is fair.
	frames := make([][]float32, p.windowFrames+p.scoreFrames)
	refs := make([][]byte, len(frames))
	trueDC := make([]float64, len(frames))
	for i := range frames {
		frames[i], refs[i] = channel.Frame(rng, symbols, p.samplesPerSymbol, float32(amplitude), noise)
		trueDC[i] = channel.DC()
	}

	// Features: the raw, filter-independent metrics ReceiverMetrics carries.
	throwaway := dsp.NewKalman(1e-4, 1)
	snr := make([]float64, p.windowFrames)
	nv := make([]float64, p.windowFrames)
	fm := make([]float64, p.windowFrames)
	for i := 0; i < p.windowFrames; i++ {
		m := dsp.ProcessBPSK(throwaway, frames[i], p.samplesPerSymbol, refs[i])
		snr[i], nv[i], fm[i] = math.Min(m.SNRDB, 60), m.NoiseVariance, m.FrameMean
	}
	r := row{amplitude: amplitude, noise: noise, channel: settings, features: windowFeatures(snr, nv, fm), dcRMSE: math.Inf(1)}

	bestErrors := uint64(math.MaxUint64)
	for _, rho := range p.grid {
		k := dsp.NewKalman(rho, 1)
		var errors, compared uint64
		var sq float64
		for i := p.windowFrames; i < len(frames); i++ {
			m := dsp.ProcessBPSK(k, frames[i], p.samplesPerSymbol, refs[i])
			errors, compared = errors+m.Errors, compared+m.Compared
			d := m.DCEstimate - trueDC[i]
			sq += d * d
		}
		rmse := math.Sqrt(sq / float64(p.scoreFrames))
		r.bers = append(r.bers, float64(errors)/float64(compared))
		if errors < bestErrors || (errors == bestErrors && rmse < r.dcRMSE) {
			bestErrors, r.dcRMSE, r.bestRho = errors, rmse, rho
		}
	}
	return r
}

// windowFeatures must match server/controller/extensions/mlpolicy.Features.
func windowFeatures(snr, nv, frameMean []float64) []float64 {
	snrMean, snrStd := meanStd(snr)
	nvMean, nvStd := meanStd(nv)
	_, fmStd := meanStd(frameMean)
	var step float64
	for i := 1; i < len(frameMean); i++ {
		step += math.Abs(frameMean[i] - frameMean[i-1])
	}
	if len(frameMean) > 1 {
		step /= float64(len(frameMean) - 1)
	}
	return []float64{snrMean, snrStd, nvMean, nvStd, fmStd, step}
}

// randomChannel draws the impairments for one scenario: about 30% are clean
// AWGN; the rest independently get slow fading, DC drift and/or noise bursts.
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

func write(path string, p params, rows []row) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()
	w := csv.NewWriter(f)
	header := []string{"amplitude", "noise_stddev", "fading_depth", "fading_period_samples", "drift_stddev", "drift_reversion", "burst_probability", "burst_multiplier"}
	header = append(header, featureNames...)
	header = append(header, "best_rho", "dc_rmse")
	for _, g := range p.grid {
		header = append(header, "ber_rho_"+strconv.FormatFloat(g, 'g', 6, 64))
	}
	if err := w.Write(header); err != nil {
		return err
	}
	for _, r := range rows {
		c := r.channel
		rec := []string{ff(r.amplitude), ff(r.noise), ff(c.FadingDepth), ff(c.FadingPeriodSamples), ff(c.DriftStddev), ff(c.DriftReversion), ff(c.BurstProbability), ff(c.BurstNoiseMultiplier)}
		for _, v := range r.features {
			rec = append(rec, ff(v))
		}
		rec = append(rec, ff(r.bestRho), ff(r.dcRMSE))
		for _, b := range r.bers {
			rec = append(rec, ff(b))
		}
		if err := w.Write(rec); err != nil {
			return err
		}
	}
	w.Flush()
	return w.Error()
}

func uniform(rng *rand.Rand, lo, hi float64) float64 { return lo + rng.Float64()*(hi-lo) }

func meanStd(v []float64) (float64, float64) {
	var sum, sq float64
	for _, x := range v {
		sum += x
	}
	mean := sum / float64(len(v))
	for _, x := range v {
		sq += (x - mean) * (x - mean)
	}
	return mean, math.Sqrt(sq / float64(len(v)))
}

func ff(v float64) string { return strconv.FormatFloat(v, 'g', 8, 64) }
