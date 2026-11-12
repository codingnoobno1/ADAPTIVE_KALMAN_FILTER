// Live monitoring panels. Every value shown is read from LiveLab, which only
// holds data received from the three nodes. Missing values are labelled as
// missing, never filled with placeholders.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:livekalman_sdk/livekalman_sdk.dart' as lk;

import 'live_lab.dart';
import 'main.dart'
    show
        AppPanel,
        PanelTitle,
        SignalChart,
        amber,
        blue,
        ink,
        line,
        mint,
        muted,
        rose,
        surfaceHigh;

const _violet = Color(0xffb68cff);

String _time(DateTime t) {
  String two(int v) => v.toString().padLeft(2, '0');
  final l = t.toLocal();
  return '${two(l.hour)}:${two(l.minute)}:${two(l.second)}.${l.millisecond.toString().padLeft(3, '0')}';
}

String _num(double? v, {int digits = 3, String unit = ''}) =>
    v == null || !v.isFinite ? '—' : '${v.toStringAsFixed(digits)}$unit';

Color _linkColor(lk.LinkStatus s) => switch (s) {
  lk.LinkStatus.connected => mint,
  lk.LinkStatus.checking => blue,
  lk.LinkStatus.reconnecting => amber,
  lk.LinkStatus.connectionLost => rose,
  lk.LinkStatus.serviceUnavailable => rose,
};

Color classColor(String c) => switch (c) {
  'good' => mint,
  'moderate' => blue,
  'poor' => amber,
  'unstable' => rose,
  _ => muted,
};

/// All live-monitoring panels, ordered for the active role.
class LiveMonitorSection extends StatelessWidget {
  const LiveMonitorSection({
    super.key,
    required this.lab,
    required this.roleIndex,
  });
  final LiveLab lab;
  final int roleIndex; // 0 sender, 1 receiver, 2 controller

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: lab,
    builder: (context, _) {
      final health = ConnectionHealthPanel(lab: lab);
      final probe = SignalProbePanel(lab: lab);
      final frames = LiveFramesPanel(lab: lab);
      final images = ImageQualityPanel(lab: lab);
      final ml = MlPanel(lab: lab);
      final order = switch (roleIndex) {
        0 => [health, probe, frames],
        1 => [health, probe, frames, images],
        _ => [health, ml, probe, frames, images],
      };
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final w in order) ...[w, const SizedBox(height: 14)],
        ],
      );
    },
  );
}

// ---------------------------------------------------------------- health ----

class ConnectionHealthPanel extends StatelessWidget {
  const ConnectionHealthPanel({super.key, required this.lab});
  final LiveLab lab;

  @override
  Widget build(BuildContext context) {
    const names = ['Sender', 'Receiver', 'Controller'];
    return AppPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle(
            icon: Icons.monitor_heart_rounded,
            title: 'CONNECTION HEALTH (gRPC PROBES, 1 s)',
            color: mint,
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < 3; i++) _nodeRow(names[i], lab.health[i]),
          const Divider(color: line, height: 22),
          Text(
            'TX → RX: ${lab.transmitterToReceiver}',
            key: const Key('tx-rx-summary'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final e in lab.streams.entries)
                _chip(
                  '${e.key}: ${e.value.status}'
                  '${e.value.status == streamWaiting && e.value.quietReason != null ? ' (${e.value.quietReason})' : ''}'
                  '${e.value.lastError == null ? '' : ' (${e.value.lastError})'}',
                  switch (e.value.status) {
                    streamStreaming => mint,
                    streamWaiting => blue,
                    _ => amber,
                  },
                  key: Key('stream-${e.key}'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Connected = the node answered GetNodeInfo/GetNodeStatus with the expected role before the 2 s deadline. '
            'Data Flow Active = its frame sequence advanced within the last 3 s. A reachable tunnel alone never counts as connected.',
            style: TextStyle(color: muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _nodeRow(String name, lk.NodeHealth h) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Wrap(
      spacing: 10,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        _chip(h.link.label, _linkColor(h.link), key: Key('link-$name')),
        _chip(
          h.dataFlow.label,
          h.dataFlow == lk.DataFlowStatus.active ? mint : muted,
          key: Key('flow-$name'),
        ),
        Text(
          'latency ${h.latencyMs == null ? '—' : '${h.latencyMs} ms'}',
          style: const TextStyle(color: muted, fontSize: 12),
        ),
        Text(
          'seq ${h.lastSequence ?? '—'}',
          style: const TextStyle(
            color: muted,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
        if (h.checkedAt != null)
          Text(
            'checked ${_time(h.checkedAt!)}',
            style: const TextStyle(color: muted, fontSize: 11),
          ),
        Text(h.message, style: const TextStyle(color: muted, fontSize: 11)),
      ],
    ),
  );
}

Widget _chip(String text, Color color, {Key? key}) => Container(
  key: key,
  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
  decoration: BoxDecoration(
    color: color.withValues(alpha: .12),
    borderRadius: BorderRadius.circular(99),
    border: Border.all(color: color.withValues(alpha: .35)),
  ),
  child: Text(
    text,
    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
  ),
);

// ------------------------------------------------------------ signal probe --

class SignalProbePanel extends StatelessWidget {
  const SignalProbePanel({super.key, required this.lab});
  final LiveLab lab;

  @override
  Widget build(BuildContext context) {
    final pair = lab.latestPair();
    final rxOnly = lab.rxFrames.isEmpty ? null : lab.rxFrames.last.value;
    final txOnly = lab.txFrames.isEmpty ? null : lab.txFrames.last.value;
    final tx = pair?.$1 ?? txOnly;
    final rx = pair?.$2 ?? rxOnly;
    final m = lab.latestMetrics;
    if (tx == null && rx == null) {
      return AppPanel(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            PanelTitle(
              icon: Icons.show_chart_rounded,
              title: 'SIGNAL PROBE',
              color: blue,
            ),
            SizedBox(height: 12),
            Text(
              'No live frames received yet. Start the Sender and Receiver; nothing is simulated here.',
              key: Key('probe-empty'),
              style: TextStyle(color: muted),
            ),
          ],
        ),
      );
    }
    final noisy =
        rx?.noisySamples.map((v) => v.toDouble()).toList() ?? const <double>[];
    final dc = rx?.dcEstimate.toDouble();
    final filtered = dc == null
        ? const <double>[]
        : noisy.map((v) => v - dc).toList();
    final clean = _upsample(
      tx?.cleanSymbols.map((v) => v.toDouble()).toList() ?? const [],
      8,
    );
    final detected = _bits(rx?.demodulatedBits ?? '', 16);
    final amplitude = noisy.isEmpty
        ? null
        : noisy.map((v) => v.abs()).reduce((a, b) => a + b) / noisy.length;
    final charts = [
      SignalChart(
        title: 'TRANSMITTED (CLEAN, FIRST 16 SYMBOLS)',
        valueLabel: tx == null ? 'no TX trace' : 'seq ${tx.sequence}',
        values: clean,
        color: blue,
      ),
      SignalChart(
        title: 'RECEIVED NOISY SAMPLES',
        valueLabel: rx == null ? 'no RX trace' : 'seq ${rx.sequence}',
        values: noisy,
        color: amber,
      ),
      SignalChart(
        title: 'FILTERED: NOISY − KALMAN DC ESTIMATE',
        valueLabel: 'DC ${_num(dc)}',
        values: filtered,
        color: mint,
      ),
      SignalChart(
        title: 'DETECTED BITS (±1)',
        valueLabel: '${detected.length ~/ 8} bits',
        values: detected,
        color: _violet,
      ),
    ];
    return AppPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle(
            icon: Icons.show_chart_rounded,
            title: 'SIGNAL PROBE (LIVE FRAME TRACES)',
            color: blue,
          ),
          const SizedBox(height: 6),
          Text(
            pair != null
                ? 'Transmitted and received waveforms are the same frame (sequence ${pair.$1.sequence}).'
                : 'Only one side has traces right now; waveforms are from different frames.',
            style: const TextStyle(color: muted, fontSize: 11),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth >= 900 ? 2 : 1;
              final w = (c.maxWidth - (cols - 1) * 12) / cols;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final ch in charts) SizedBox(width: w, child: ch),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _stat('Mean |sample| (amplitude)', _num(amplitude)),
              _stat(
                'Noise variance (receiver)',
                _num(m?.noiseVariance.toDouble(), digits: 4),
              ),
              _stat(
                'Estimated SNR',
                _num(m?.snrDb.toDouble(), digits: 2, unit: ' dB'),
              ),
              _stat(
                'BER',
                m == null
                    ? '—'
                    : (m.comparedBits > 0
                          ? m.ber.toStringAsExponential(2)
                          : 'no reference bits'),
              ),
              _stat(
                'Bits compared / errors',
                rx == null ? '—' : '${rx.comparedBits} / ${rx.bitErrors}',
              ),
              _stat(
                'Processing latency',
                _num(m?.latencyMs, digits: 2, unit: ' ms'),
              ),
              _stat(
                'Frames lost (receiver gaps)',
                m == null ? '—' : '${m.sequenceGaps}',
              ),
              _stat('Trace stream jumps', '${lab.rxSequenceJumps}'),
              _stat('Phase error', 'not available'),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Phase error is not shown because this BPSK pipeline carries real-valued samples and the receiver has no carrier-phase tracker. '
            '"Trace stream jumps" also counts traces the dashboard skipped when busy; "Frames lost" is the receiver\'s own count.',
            style: TextStyle(color: muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  static List<double> _upsample(List<double> symbols, int factor) => [
    for (final s in symbols) ...List.filled(factor, s),
  ];

  static List<double> _bits(String bits, int maxBits) => [
    for (final ch in bits.split('').take(maxBits))
      ...List.filled(8, ch == '1' ? 1.0 : -1.0),
  ];
}

Widget _stat(String label, String value) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: muted,
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: .8,
      ),
    ),
    const SizedBox(height: 2),
    Text(
      value,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontFamily: 'monospace',
      ),
    ),
  ],
);

// ------------------------------------------------------------ live frames ---

class LiveFramesPanel extends StatelessWidget {
  const LiveFramesPanel({super.key, required this.lab});
  final LiveLab lab;

  @override
  Widget build(BuildContext context) {
    final txBySeq = {for (final t in lab.txFrames) t.value.sequence.toInt(): t};
    final rows = lab.rxFrames.reversed.take(10).toList();
    return AppPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle(
            icon: Icons.list_alt_rounded,
            title: 'LIVE FRAMES (TX / RX ACTIVITY)',
            color: amber,
          ),
          const SizedBox(height: 8),
          Text(
            'Sender traces: ${lab.streams['sender traces']!.messages} · receiver traces: ${lab.streams['receiver traces']!.messages}'
            '${lab.latestMetricsAt == null ? '' : ' · last metrics ${_time(lab.latestMetricsAt!)}'}',
            style: const TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            const Text(
              'No received frames yet.',
              style: TextStyle(color: muted),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 30,
                dataRowMinHeight: 26,
                dataRowMaxHeight: 30,
                columnSpacing: 18,
                columns: const [
                  DataColumn(label: Text('SEQ')),
                  DataColumn(label: Text('TX STAMP (SENDER)')),
                  DataColumn(label: Text('RX STAMP (RECEIVER)')),
                  DataColumn(label: Text('SHOWN HERE')),
                  DataColumn(label: Text('BER')),
                  DataColumn(label: Text('PAYLOAD')),
                ],
                rows: [
                  for (final r in rows)
                    DataRow(
                      cells: [
                        DataCell(
                          Text(
                            '${r.value.sequence}',
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                        DataCell(
                          Text(() {
                            final t = txBySeq[r.value.sequence.toInt()];
                            return t == null
                                ? '—'
                                : _time(
                                    DateTime.fromMillisecondsSinceEpoch(
                                      t.value.observedAtUnixMs.toInt(),
                                    ),
                                  );
                          }()),
                        ),
                        DataCell(
                          Text(
                            _time(
                              DateTime.fromMillisecondsSinceEpoch(
                                r.value.observedAtUnixMs.toInt(),
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(_time(r.receivedAt))),
                        DataCell(
                          Text(
                            r.value.comparedBits > 0
                                ? r.value.ber.toStringAsExponential(1)
                                : 'n/a',
                          ),
                        ),
                        DataCell(
                          Text(
                            r.value.fileName.isEmpty
                                ? 'idle stream'
                                : '${r.value.fileName} @${r.value.mediaOffset}',
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          const Text(
            'Timestamps come from each node\'s own clock; compare them across laptops only if the clocks are NTP-synchronised.',
            style: TextStyle(color: muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------- image quality ----

class ImageQualityPanel extends StatelessWidget {
  const ImageQualityPanel({super.key, required this.lab});
  final LiveLab lab;

  @override
  Widget build(BuildContext context) {
    final items = lab.transfers.values.toList().reversed.take(4).toList();
    return AppPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle(
            icon: Icons.image_search_rounded,
            title: 'IMAGE QUALITY (ORIGINAL VS RECONSTRUCTED)',
            color: _violet,
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text(
              'No file transfers observed yet. Send a BMP from the Sender; PSNR and SSIM need both the original (Sender traces) and the reconstruction (Receiver media).',
              style: TextStyle(color: muted),
            ),
          for (final x in items) _transfer(x),
        ],
      ),
    );
  }

  Widget _transfer(ImageTransfer x) {
    final m = x.metrics;
    final status = m != null
        ? 'MSE ${m.mse.toStringAsFixed(2)} · PSNR ${m.psnr.isFinite ? '${m.psnr.toStringAsFixed(2)} dB' : '∞ (identical)'} · SSIM ${m.ssim.toStringAsFixed(4)}'
        : x.error ??
              (!x.originalComplete && x.reconstructedComplete
                  ? 'Original incomplete: ${x.originalBytesSeen} of ${x.originalTotal == 0 ? '?' : x.originalTotal} bytes seen in Sender traces '
                        '(the dashboard was probably connected after the transfer started), so PSNR/SSIM are not computed'
                  : !x.originalComplete
                  ? 'Waiting for the full original from Sender traces'
                  : !x.reconstructedComplete
                  ? 'Waiting for the receiver to finish the reconstruction'
                  : 'Comparing…');
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${x.fileName} · CRC ${x.checksumValid == null ? 'pending' : (x.checksumValid! ? 'valid' : 'MISMATCH')}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            key: Key('image-metrics-${x.key}'),
            style: TextStyle(
              color: m == null ? muted : mint,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
          if (m != null)
            Text(
              m.preprocessing,
              style: const TextStyle(color: muted, fontSize: 11),
            ),
          if (m != null && x.original != null && x.reconstructed != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 12,
                children: [
                  _image('ORIGINAL', x.original!),
                  _image('RECONSTRUCTED', x.reconstructed!),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _image(String label, Uint8List bytes) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: muted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 4),
      Container(
        decoration: BoxDecoration(border: Border.all(color: line)),
        child: Image.memory(
          bytes,
          width: 192,
          filterQuality: FilterQuality.none,
          gaplessPlayback: true,
          errorBuilder: (context, error, stack) => const SizedBox(
            width: 192,
            height: 60,
            child: Center(
              child: Text(
                'header damaged: cannot display',
                style: TextStyle(color: rose, fontSize: 11),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

// -------------------------------------------------------------------- ML ----

class MlPanel extends StatelessWidget {
  const MlPanel({super.key, required this.lab});
  final LiveLab lab;

  @override
  Widget build(BuildContext context) {
    final latest = lab.assessments.isEmpty ? null : lab.assessments.last;
    final a = latest?.assessment;
    final metrics = lab.latestMetrics;
    final decision = lab.decisions.isEmpty ? null : lab.decisions.last.decision;
    final live = lab.liveAccuracy();
    final report = lab.modelReport;
    return AppPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle(
            icon: Icons.psychology_rounded,
            title: 'ML CHANNEL QUALITY & ADAPTATION',
            color: _violet,
          ),
          const SizedBox(height: 12),
          if (a == null)
            const Text(
              'No channel assessment yet: the controller publishes one per 12-frame window.',
              style: TextStyle(color: muted),
            )
          else
            Wrap(
              spacing: 14,
              runSpacing: 12,
              children: [
                _box(
                  'MEASURED (RULES, THIS WINDOW)',
                  a.measuredClass.toUpperCase(),
                  classColor(a.measuredClass),
                  'frames ${a.windowFirstSequence}–${a.windowLastSequence}',
                  key: const Key('ml-measured'),
                ),
                _box(
                  'PREDICTED (MODEL, NEXT ${a.horizonFrames} FRAMES)',
                  a.predictedClass.isEmpty
                      ? 'NO MODEL'
                      : a.predictedClass.toUpperCase(),
                  a.predictedClass.isEmpty
                      ? muted
                      : classColor(a.predictedClass),
                  a.predictedClass.isEmpty
                      ? 'set controller.qualityModel'
                      : 'confidence ${(a.confidence * 100).toStringAsFixed(0)}%',
                  key: const Key('ml-predicted'),
                ),
                _box(
                  'RECOMMENDED Q/R (POLICY)',
                  decision == null
                      ? '—'
                      : 'ρ ${_ratio(decision.proposedKalmanQ, decision.proposedKalmanR)}',
                  blue,
                  decision == null
                      ? 'no decision yet'
                      : '${decision.policy} · v${decision.proposedVersion} · ${decision.sentToReceiver ? 'sent to receiver' : 'NOT sent (recommend-only)'}',
                ),
                _box(
                  'APPLIED Q/R (RECEIVER)',
                  metrics == null || metrics.activeKalmanR == 0
                      ? '—'
                      : 'ρ ${_ratio(metrics.activeKalmanQ, metrics.activeKalmanR)}',
                  mint,
                  metrics == null
                      ? 'no metrics yet'
                      : 'config v${metrics.activeConfigVersion} · Q ${metrics.activeKalmanQ.toStringAsExponential(2)} R ${metrics.activeKalmanR.toStringAsFixed(3)}',
                ),
              ],
            ),
          if (a != null && a.classProbabilities.length == 4) ...[
            const SizedBox(height: 12),
            for (var i = 0; i < 4; i++)
              _probBar(
                const ['good', 'moderate', 'poor', 'unstable'][i],
                a.classProbabilities[i],
              ),
          ],
          if (a != null && a.features.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'MODEL INPUTS (MEASURED, THIS WINDOW)',
              style: TextStyle(
                color: muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                for (
                  var i = 0;
                  i < a.features.length && i < a.featureNames.length;
                  i++
                )
                  Text(
                    '${a.featureNames[i]} = ${a.features[i].toStringAsPrecision(3)}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ],
          const Divider(color: line, height: 24),
          Text(
            live == null
                ? 'Live prediction check: waiting for a predicted window to be measured.'
                : 'Live prediction check: ${live.correct}/${live.checked} predictions matched the next measured window '
                      '(${(100 * live.correct / live.checked).toStringAsFixed(1)}%).',
            key: const Key('ml-live-accuracy'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          _history(),
          const Divider(color: line, height: 24),
          Text(
            'Model: ${a?.modelVersion.isNotEmpty == true ? a!.modelVersion : '—'} · report ${lab.modelReportStatus}',
            style: const TextStyle(color: muted, fontSize: 11),
          ),
          if (report != null) _reportSummary(report),
          const SizedBox(height: 6),
          const Text(
            'Measured classes come from fixed rules on receiver metrics; predictions come from the ONNX model; '
            'recommended Q/R come from the adaptation policy; applied Q/R are what the receiver reports it used. '
            'The model was trained on simulated channels (cmd/qualitygen).',
            style: TextStyle(color: muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  static String _ratio(double q, double r) =>
      r == 0 ? '—' : (q / r).toStringAsExponential(2);

  Widget _box(
    String label,
    String value,
    Color color,
    String sub, {
    Key? key,
  }) => Container(
    key: key,
    width: 250,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: surfaceHigh,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: .35)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: muted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(sub, style: const TextStyle(color: muted, fontSize: 11)),
      ],
    ),
  );

  Widget _probBar(String name, double p) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(name, style: const TextStyle(fontSize: 11)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: p.clamp(0, 1),
              minHeight: 8,
              backgroundColor: ink,
              color: classColor(name),
            ),
          ),
        ),
        SizedBox(
          width: 52,
          child: Text(
            ' ${(p * 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
          ),
        ),
      ],
    ),
  );

  Widget _history() {
    final items = lab.assessments.reversed.take(8).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final r in items)
          Tooltip(
            message:
                'frames ${r.assessment.windowFirstSequence}–${r.assessment.windowLastSequence}\n'
                'measured ${r.assessment.measuredClass}, predicted next ${r.assessment.predictedClass.isEmpty ? '—' : r.assessment.predictedClass}'
                '${r.actualNext == null ? '' : ', actual next ${r.actualNext}'}',
            child: _chip(
              '${r.assessment.measuredClass[0].toUpperCase()}→${r.assessment.predictedClass.isEmpty ? '?' : r.assessment.predictedClass[0].toUpperCase()}'
              '${r.correct == null ? '' : (r.correct! ? ' ✓' : ' ✗')}',
              r.correct == null ? muted : (r.correct! ? mint : rose),
            ),
          ),
      ],
    );
  }

  Widget _reportSummary(Map<String, Object?> report) {
    Map<String, Object?>? m(Object? v) =>
        v is Map ? v.cast<String, Object?>() : null;
    final test = m(report['test']);
    final chosen = report['chosen_model']?.toString();
    final model = test == null || chosen == null ? null : m(test[chosen]);
    final base = test == null ? null : m(test['persistence_baseline']);
    String pct(Object? v) =>
        v is num ? '${(v * 100).toStringAsFixed(1)}%' : '—';
    String f(Object? v) => v is num ? v.toStringAsFixed(3) : '—';
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        'Offline test set (simulated, unseen scenarios): $chosen accuracy ${pct(model?['accuracy'])}, macro-F1 ${f(model?['macro_f1'])}; '
        'persistence baseline ${pct(base?['accuracy'])}, macro-F1 ${f(base?['macro_f1'])}; '
        'correct when the class changes ${pct(model?['accuracy_when_class_changes'])}.',
        key: const Key('ml-report'),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
