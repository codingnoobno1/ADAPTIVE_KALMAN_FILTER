# Machine Learning Policy (`ml/`)

This directory contains the Python training, verification, dataset, and exported ONNX policy artifacts used by the Go Experiment Controller (`server/controller/extensions/mlpolicy`).

## Directory Structure

```text
ml/
  requirements.txt          Python dependencies (numpy, scikit-learn, onnx, onnxruntime, nanopb)
  train.py                  Trains the 6 -> 16 -> 16 -> 1 ReLU MLP and exports opset-13 ONNX
  verify_model.py           Validates ONNX IR/opset/operator whitelist, golden parity & BER gains
  export_results.py         Exports reproducible benchmark CSVs from dataset.csv + report.json to ../results/
  data/
    dataset.csv             6,000 simulated BPSK channels x 29 candidate Kalman rho=Q/R ratios
  models/
    r_policy.onnx           Exported pure-Go gonnx-compatible policy graph (IR v8, opset 13)
    r_policy.golden.json    32 held-out feature vectors & onnxruntime log(rho) predictions
    report.json             Held-out 1,200-channel evaluation report across SNR bands & drift regimes
```

## Reproducing the Dataset, Model & Results

```powershell
# 1. Install dependencies
python -m venv ml\.venv
ml\.venv\Scripts\python.exe -m pip install -r ml\requirements.txt

# 2. (Optional) Regenerate the 6,000-scenario dataset from the live Go DSP code
go run ./cmd/datagen -out ml/data/dataset.csv

# 3. Train & export the ONNX policy and golden test vectors
ml\.venv\Scripts\python.exe ml\train.py --data ml/data/dataset.csv --out ml/models

# 4. Audit ONNX operator compatibility, golden parity & Go gonnx parity
ml\.venv\Scripts\python.exe ml\verify_model.py --models-dir ml/models --min-r2 0.40 --require-drift-gain
go test -v ./server/controller/extensions/mlpolicy

# 5. Refresh structured CSV tables in ../results/
ml\.venv\Scripts\python.exe ml\export_results.py
```
