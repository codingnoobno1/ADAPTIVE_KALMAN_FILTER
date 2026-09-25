# ESP32 protobuf producer

Laptop 2 exposes `POST /api/v1/frames` on port `8082`. The request body is a binary `TxFrame`; the response body is a binary `RxFeedback`. This avoids requiring full gRPC/HTTP2 support on the microcontroller while preserving the same versioned protobuf contract.

1. Install PlatformIO, Nanopb, and the Arduino ESP32 framework.
2. Generate Nanopb C sources from `proto/rx/v1/receiver.proto` plus its imports and `.options` file.
3. Place generated `receiver.pb.c/.h` and `common.pb.c/.h` under `platformio/src`.
4. Add `nanopb/Nanopb` as a PlatformIO dependency and update Wi-Fi credentials/address in `main.cpp`.
5. Keep DMA/sample acquisition separate from HTTP transmission and use a bounded queue. Do not transmit from an interrupt handler.

The sample limits in `receiver.options` match the receiver's bounded frame policy. For production, enable TLS, authenticate the device, rotate credentials, and use packed `int16` data to reduce bandwidth.

