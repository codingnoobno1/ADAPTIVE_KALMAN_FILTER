"""Independent NumPy reference for the image metrics in shared/quality.

Used to cross-check the Go implementation (shared/quality/quality_test.go):
SSIM after Wang et al. (2004) with an 11x11 Gaussian window (sigma 1.5),
K1 = 0.01, K2 = 0.03, L = 255, mean over every full window position, on
BT.601 luma. MSE/PSNR are over all 8-bit RGB samples.

Run: python ml/quality_reference.py
"""

from __future__ import annotations

import numpy as np


def luma(rgb: np.ndarray) -> np.ndarray:
    return 0.299 * rgb[..., 0] + 0.587 * rgb[..., 1] + 0.114 * rgb[..., 2]


def ssim(x: np.ndarray, y: np.ndarray) -> float:
    size, sigma = 11, 1.5
    c1, c2 = (0.01 * 255) ** 2, (0.03 * 255) ** 2
    ax = np.arange(size) - size // 2
    g = np.exp(-(ax[:, None] ** 2 + ax[None, :] ** 2) / (2 * sigma**2))
    g /= g.sum()
    h, w = x.shape
    vals = []
    for top in range(h - size + 1):
        for left in range(w - size + 1):
            px = x[top : top + size, left : left + size]
            py = y[top : top + size, left : left + size]
            mx, my = (g * px).sum(), (g * py).sum()
            sxx = (g * (px - mx) ** 2).sum()
            syy = (g * (py - my) ** 2).sum()
            sxy = (g * (px - mx) * (py - my)).sum()
            vals.append(((2 * mx * my + c1) * (2 * sxy + c2)) / ((mx**2 + my**2 + c1) * (sxx + syy + c2)))
    return float(np.mean(vals))


def test_pair(w: int = 20, h: int = 16):
    """The same deterministic pair as TestSSIMMatchesReferenceImplementation."""
    i = np.arange(w * h * 3)
    a = ((i * 37 + (i // 3) * 11) % 200).astype(np.int64)
    b = (a + (i * 7) % 23) % 256
    return a.reshape(h, w, 3).astype(np.float64), b.reshape(h, w, 3).astype(np.float64)


if __name__ == "__main__":
    a, b = test_pair()
    mse = float(np.mean((a - b) ** 2))
    print(f"MSE={mse:.10f} PSNR={10 * np.log10(255**2 / mse):.10f} SSIM={ssim(luma(a), luma(b)):.10f}")
