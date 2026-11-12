// Command imgquality compares an original and a reconstructed BMP and prints
// MSE, PSNR and SSIM as JSON (see shared/quality for the exact definitions).
//
//	go run ./cmd/imgquality -original examples/media/kalman.bmp -reconstructed received/kalman.bmp
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"math"
	"os"

	"github.com/streaming-live-kalman/filter/shared/quality"
)

func main() {
	original := flag.String("original", "", "path of the transmitted BMP")
	reconstructed := flag.String("reconstructed", "", "path of the received/reconstructed BMP")
	flag.Parse()
	if *original == "" || *reconstructed == "" {
		fmt.Fprintln(os.Stderr, "both -original and -reconstructed are required")
		os.Exit(2)
	}
	a, err := os.ReadFile(*original)
	if err != nil {
		fail(err)
	}
	b, err := os.ReadFile(*reconstructed)
	if err != nil {
		fail(err)
	}
	m, err := quality.CompareBMP(a, b)
	if err != nil {
		fail(err)
	}
	var psnr any = m.PSNR
	if math.IsInf(m.PSNR, 1) {
		psnr = "infinite (identical images)"
	}
	out := map[string]any{"width": m.Width, "height": m.Height, "mse": m.MSE, "psnr_db": psnr, "ssim": m.SSIM, "preprocessing": m.Preprocessing}
	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "  ")
	_ = enc.Encode(out)
}

func fail(err error) {
	fmt.Fprintln(os.Stderr, "imgquality:", err)
	os.Exit(1)
}
