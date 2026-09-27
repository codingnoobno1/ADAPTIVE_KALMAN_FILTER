# Device 2 handover

Start with `git status`, `docs/IMPLEMENTATION_STATUS.md`, and
`docs/TEST_REPORT.md`. The checked-out branch is `main`. Common media messages
and `MediaStreamService`, plus optional receiver-frame media metadata, have
been added and generated for Go and Dart.

The current milestone includes receiver core validation in
`server/receiver/core/service.go`, config Q/R validation in
`shared/config/config.go`, media reassembly/detection in `media.go`, and tests.
Tests pass with `.tools/go/bin/go.exe` (see `TEST_REPORT.md`); run them before
changing this work.

Do not implement QPSK/8-PSK or complex I/Q by reusing the old standalone
Python project. The receiver supports only real BPSK even though its application
media metadata now identifies modulation explicitly. A future complex I/Q or
QPSK extension must update Sender/Receiver mappings together and regenerate
code with `scripts/generate.ps1`. AI Q/R must remain compatible with the
Controller's existing R policy rather than introducing a second runtime policy.
