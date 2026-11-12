package quality

import (
	"encoding/binary"
	"errors"
	"fmt"
	"math"
)

// Image is an 8-bit RGB image in row-major, top-down order.
type Image struct {
	Width, Height int
	RGB           []uint8 // len = Width*Height*3
}

// Luma returns BT.601 luma (0.299 R + 0.587 G + 0.114 B) as float64.
func (im Image) Luma() []float64 {
	out := make([]float64, im.Width*im.Height)
	for i := range out {
		r, g, b := float64(im.RGB[3*i]), float64(im.RGB[3*i+1]), float64(im.RGB[3*i+2])
		out[i] = 0.299*r + 0.587*g + 0.114*b
	}
	return out
}

// BMPLayout is the pixel geometry read from a BMP header.
type BMPLayout struct {
	Width, Height int
	BitsPerPixel  int
	PixelOffset   int
	RowStride     int
	TopDown       bool
}

// ParseBMPLayout reads an uncompressed 24- or 32-bit BMP header.
func ParseBMPLayout(b []byte) (BMPLayout, error) {
	if len(b) < 54 || b[0] != 'B' || b[1] != 'M' {
		return BMPLayout{}, errors.New("not a BMP file")
	}
	offset := int(binary.LittleEndian.Uint32(b[10:14]))
	width := int(int32(binary.LittleEndian.Uint32(b[18:22])))
	height := int(int32(binary.LittleEndian.Uint32(b[22:26])))
	bpp := int(binary.LittleEndian.Uint16(b[28:30]))
	compression := binary.LittleEndian.Uint32(b[30:34])
	if compression != 0 && compression != 3 {
		return BMPLayout{}, fmt.Errorf("compressed BMP (type %d) is not supported", compression)
	}
	if bpp != 24 && bpp != 32 {
		return BMPLayout{}, fmt.Errorf("%d-bit BMP is not supported (24 or 32 only)", bpp)
	}
	topDown := height < 0
	if topDown {
		height = -height
	}
	if width <= 0 || height <= 0 || width > 16384 || height > 16384 {
		return BMPLayout{}, fmt.Errorf("invalid BMP size %dx%d", width, height)
	}
	stride := ((width*bpp/8 + 3) / 4) * 4
	return BMPLayout{Width: width, Height: height, BitsPerPixel: bpp, PixelOffset: offset, RowStride: stride, TopDown: topDown}, nil
}

// Decode reads the pixels of b using this layout (b's own header is ignored).
func (l BMPLayout) Decode(b []byte) (Image, error) {
	need := l.PixelOffset + l.RowStride*l.Height
	if len(b) < need {
		return Image{}, fmt.Errorf("pixel data incomplete: have %d bytes, need %d", len(b), need)
	}
	bytesPP := l.BitsPerPixel / 8
	im := Image{Width: l.Width, Height: l.Height, RGB: make([]uint8, l.Width*l.Height*3)}
	for y := 0; y < l.Height; y++ {
		srcRow := y
		if !l.TopDown {
			srcRow = l.Height - 1 - y
		}
		row := b[l.PixelOffset+srcRow*l.RowStride:]
		for x := 0; x < l.Width; x++ {
			p := row[x*bytesPP:]
			o := 3 * (y*l.Width + x)
			im.RGB[o], im.RGB[o+1], im.RGB[o+2] = p[2], p[1], p[0] // BGR -> RGB
		}
	}
	return im, nil
}

// ImageMetrics compares an original and a reconstructed image.
type ImageMetrics struct {
	Width, Height int
	// MSE and PSNR are over all R, G and B samples (8-bit, peak 255).
	MSE  float64
	PSNR float64 // +Inf when the images are identical
	// SSIM is computed on BT.601 luma with an 11x11 Gaussian window
	// (sigma 1.5), K1 = 0.01, K2 = 0.03, L = 255 (Wang et al., 2004),
	// averaged over every full window position.
	SSIM          float64
	Preprocessing string
}

// CompareBMP decodes both files with the ORIGINAL's header geometry, because
// bit errors can corrupt the reconstructed header while its pixel bytes are
// still at the same offsets. It fails if either file cannot supply the pixels.
func CompareBMP(original, reconstructed []byte) (ImageMetrics, error) {
	layout, err := ParseBMPLayout(original)
	if err != nil {
		return ImageMetrics{}, fmt.Errorf("original: %w", err)
	}
	a, err := layout.Decode(original)
	if err != nil {
		return ImageMetrics{}, fmt.Errorf("original: %w", err)
	}
	b, err := layout.Decode(reconstructed)
	if err != nil {
		return ImageMetrics{}, fmt.Errorf("reconstructed: %w", err)
	}
	m, err := Compare(a, b)
	if err != nil {
		return ImageMetrics{}, err
	}
	m.Preprocessing = fmt.Sprintf("BMP %dx%d, %d-bit, uint8 RGB; reconstructed pixels read with the original header geometry; SSIM on BT.601 luma", layout.Width, layout.Height, layout.BitsPerPixel)
	return m, nil
}

// Compare computes MSE, PSNR and SSIM for two images of identical size.
func Compare(a, b Image) (ImageMetrics, error) {
	if a.Width != b.Width || a.Height != b.Height || len(a.RGB) != len(b.RGB) {
		return ImageMetrics{}, fmt.Errorf("image sizes differ: %dx%d vs %dx%d", a.Width, a.Height, b.Width, b.Height)
	}
	if a.Width < 11 || a.Height < 11 {
		return ImageMetrics{}, errors.New("images must be at least 11x11 for SSIM")
	}
	var se float64
	for i := range a.RGB {
		d := float64(a.RGB[i]) - float64(b.RGB[i])
		se += d * d
	}
	mse := se / float64(len(a.RGB))
	psnr := math.Inf(1)
	if mse > 0 {
		psnr = 10 * math.Log10(255*255/mse)
	}
	return ImageMetrics{Width: a.Width, Height: a.Height, MSE: mse, PSNR: psnr, SSIM: SSIM(a.Luma(), b.Luma(), a.Width, a.Height)}, nil
}

// SSIM implements the mean structural similarity of two grayscale images.
func SSIM(x, y []float64, width, height int) float64 {
	const size, sigma = 11, 1.5
	const c1, c2 = (0.01 * 255) * (0.01 * 255), (0.03 * 255) * (0.03 * 255)
	var w [size * size]float64
	var sum float64
	for i := 0; i < size; i++ {
		for j := 0; j < size; j++ {
			di, dj := float64(i-size/2), float64(j-size/2)
			w[i*size+j] = math.Exp(-(di*di + dj*dj) / (2 * sigma * sigma))
			sum += w[i*size+j]
		}
	}
	for i := range w {
		w[i] /= sum
	}
	var total float64
	var count int
	for top := 0; top+size <= height; top++ {
		for left := 0; left+size <= width; left++ {
			var mx, my, sxx, syy, sxy float64
			for i := 0; i < size; i++ {
				row := (top + i) * width
				for j := 0; j < size; j++ {
					k, p := w[i*size+j], row+left+j
					mx += k * x[p]
					my += k * y[p]
				}
			}
			for i := 0; i < size; i++ {
				row := (top + i) * width
				for j := 0; j < size; j++ {
					k, p := w[i*size+j], row+left+j
					dx, dy := x[p]-mx, y[p]-my
					sxx += k * dx * dx
					syy += k * dy * dy
					sxy += k * dx * dy
				}
			}
			total += ((2*mx*my + c1) * (2*sxy + c2)) / ((mx*mx + my*my + c1) * (sxx + syy + c2))
			count++
		}
	}
	return total / float64(count)
}
