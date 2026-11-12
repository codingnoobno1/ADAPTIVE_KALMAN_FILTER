import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:livekalman_sdk/livekalman_sdk.dart' as lk;

import 'dsp/kalman_engine.dart';
import 'models/kalman_parameters.dart';
import 'services/live_telemetry_controller.dart';
import 'widgets/parameter_cards.dart';
import 'widgets/telemetry_charts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KalmanMobileApp());
}

/// Root widget for the **Kalman Parameter Lab** mobile application.
class KalmanMobileApp extends StatefulWidget {
  const KalmanMobileApp({
    super.key,
    this.autoPlay = true,
    this.initialEndpoint = defaultMobileEndpoint,
  });

  final bool autoPlay;
  final String initialEndpoint;

  @override
  State<KalmanMobileApp> createState() => _KalmanMobileAppState();
}

class _KalmanMobileAppState extends State<KalmanMobileApp> {
  late final TelemetryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TelemetryController(
      autoPlay: widget.autoPlay,
      initialEndpoint: widget.initialEndpoint,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkScheme = ColorScheme.fromSeed(
      seedColor: kMint,
      brightness: Brightness.dark,
      surface: kSurface,
    );
    return MaterialApp(
      title: 'Kalman Parameter Lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: darkScheme,
        scaffoldBackgroundColor: kBgInk,
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: kSurface,
          indicatorColor: kMint.withValues(alpha: 0.18),
        ),
      ),
      home: KalmanMobileShell(controller: _controller),
    );
  }
}

class KalmanMobileShell extends StatefulWidget {
  const KalmanMobileShell({super.key, required this.controller});
  final TelemetryController controller;

  @override
  State<KalmanMobileShell> createState() => _KalmanMobileShellState();
}

class _KalmanMobileShellState extends State<KalmanMobileShell> {
  int _tabIndex = 0;
  ParameterCategory? _selectedCategory;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final width = MediaQuery.sizeOf(context).width;
      final isWide = width >= 840;
      final snap = widget.controller.latest;

      final pages = <Widget>[
        _ParametersTab(
          controller: widget.controller,
          selectedCategory: _selectedCategory,
          searchQuery: _searchQuery,
          onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
          onSearchChanged: (q) => setState(() => _searchQuery = q),
        ),
        _ChartsTab(controller: widget.controller),
        _OnDeviceWorkbenchTab(controller: widget.controller),
        _LiveThreeNodeLinkTab(controller: widget.controller),
      ];

      return Scaffold(
        appBar: AppBar(
          backgroundColor: kSurface,
          elevation: 0,
          titleSpacing: 14,
          title: Row(
            children: [
              const Icon(Icons.radar_rounded, color: kMint, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Kalman Parameter Lab',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16.5,
                  ),
                ),
              ),
              _SourceBadge(controller: widget.controller, snapshot: snap),
            ],
          ),
          actions: [
            if (widget.controller.mode == TelemetrySourceMode.onDeviceLab)
              IconButton(
                key: const Key('toggle-playback-btn'),
                tooltip: widget.controller.isPlaying ? 'Pause' : 'Play',
                onPressed: widget.controller.toggleOnDevicePlayback,
                icon: Icon(
                  widget.controller.isPlaying
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded,
                  color: kMint,
                ),
              ),
            IconButton(
              key: const Key('export-json-btn'),
              tooltip: 'Inspect JSON Telemetry Snapshot',
              onPressed: () => _showSnapshotJsonDialog(context, snap),
              icon: const Icon(Icons.data_object_rounded, color: kBlue),
            ),
          ],
        ),
        body: isWide
            ? Row(
                children: [
                  NavigationRail(
                    backgroundColor: kSurface,
                    selectedIndex: _tabIndex,
                    onDestinationSelected: (idx) =>
                        setState(() => _tabIndex = idx),
                    labelType: NavigationRailLabelType.all,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.grid_view_rounded),
                        label: Text('Parameters'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.ssid_chart_rounded),
                        label: Text('Charts'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.science_rounded),
                        label: Text('Lab'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.hub_rounded),
                        label: Text('Live Link'),
                      ),
                    ],
                  ),
                  const VerticalDivider(width: 1, color: kLine),
                  Expanded(child: pages[_tabIndex]),
                ],
              )
            : pages[_tabIndex],
        bottomNavigationBar: isWide
            ? null
            : NavigationBar(
                key: const Key('mobile-bottom-nav'),
                selectedIndex: _tabIndex,
                onDestinationSelected: (idx) => setState(() => _tabIndex = idx),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.grid_view_rounded),
                    label: 'Parameters',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.ssid_chart_rounded),
                    label: 'Charts',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.science_rounded),
                    label: 'Lab',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.hub_rounded),
                    label: 'Live Link',
                  ),
                ],
              ),
      );
    },
  );

  void _showSnapshotJsonDialog(
    BuildContext context,
    KalmanParameterSnapshot snap,
  ) {
    final pretty = snap.toPrettyJson();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurface,
        title: const Text('Telemetry Snapshot (JSON)'),
        content: SizedBox(
          width: 480,
          height: 340,
          child: SingleChildScrollView(
            child: SelectableText(
              pretty,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                color: kMint,
              ),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              unawaited(Clipboard.setData(ClipboardData(text: pretty)));
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy JSON'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.controller, required this.snapshot});
  final TelemetryController controller;
  final KalmanParameterSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final isLive = controller.mode == TelemetrySourceMode.liveThreeNodeGrpc;
    final color = isLive ? kBlue : kMint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        '${controller.mode.label} · #${snapshot.sequence}',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

// =============================================================================
// TAB 1: ALL-PARAMETER MATRIX & FORMULA INSPECTOR
// =============================================================================

class _ParametersTab extends StatelessWidget {
  const _ParametersTab({
    required this.controller,
    required this.selectedCategory,
    required this.searchQuery,
    required this.onCategoryChanged,
    required this.onSearchChanged,
  });

  final TelemetryController controller;
  final ParameterCategory? selectedCategory;
  final String searchQuery;
  final ValueChanged<ParameterCategory?> onCategoryChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final snap = controller.latest;
    final all = snap.toDescriptors();
    final qLower = searchQuery.trim().toLowerCase();
    final filtered = all.where((d) {
      if (selectedCategory != null && d.category != selectedCategory) {
        return false;
      }
      if (qLower.isEmpty) return true;
      return d.name.toLowerCase().contains(qLower) ||
          d.symbol.toLowerCase().contains(qLower) ||
          d.description.toLowerCase().contains(qLower);
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 900
            ? 3
            : (constraints.maxWidth >= 560 ? 2 : 1);
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroSummaryBanner(snapshot: snap),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('parameter-search-field'),
                      onChanged: onSearchChanged,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText:
                            'Filter 25 parameters (e.g. gain, NIS, Q/R, SNR, BER, PSNR)...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        filled: true,
                        fillColor: kSurface,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: kLine),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: kLine),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: Text('All (${all.length})'),
                            selected: selectedCategory == null,
                            onSelected: (_) => onCategoryChanged(null),
                          ),
                          const SizedBox(width: 8),
                          for (final cat in ParameterCategory.values) ...[
                            FilterChip(
                              label: Text(cat.label),
                              selected: selectedCategory == cat,
                              onSelected: (_) => onCategoryChanged(
                                selectedCategory == cat ? null : cat,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (cols == 1)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) =>
                      ParameterMetricTile(descriptor: filtered[idx]),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 128,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, idx) =>
                        ParameterMetricTile(descriptor: filtered[idx]),
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HeroSummaryBanner extends StatelessWidget {
  const _HeroSummaryBanner({required this.snapshot});
  final KalmanParameterSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final nisOk = snapshot.nisConsistent95;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kSurfaceHigh, kSurface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kLine),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _miniStat('x_k (DC)', '${snapshot.stateEstimateX.toStringAsFixed(4)} V', kMint),
          _miniStat('K_k (Gain)', snapshot.kalmanGainK.toStringAsFixed(4), kBlue),
          _miniStat('P_k (Cov)', snapshot.posteriorCovarianceP.toStringAsFixed(5), kBlue),
          _miniStat('ρ = Q/R', snapshot.trackingRatioRho.toStringAsFixed(4), kViolet),
          _miniStat(
            'NIS χ²(1)',
            '${snapshot.normalizedInnovationSquared.toStringAsFixed(2)} ${nisOk ? '✓' : '!'}',
            nisOk ? kMint : kAmber,
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: const TextStyle(color: kMuted, fontSize: 10.5)),
      const SizedBox(height: 2),
      Text(
        value,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontFamily: 'monospace',
          fontSize: 13.5,
        ),
      ),
    ],
  );
}

// =============================================================================
// TAB 2: REAL-TIME KALMAN & CHANNEL OSCILLOSCOPE CHARTS
// =============================================================================

class _ChartsTab extends StatelessWidget {
  const _ChartsTab({required this.controller});
  final TelemetryController controller;

  @override
  Widget build(BuildContext context) {
    final hist = controller.history;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        MultiSeriesChartCard(
          title: 'STATE TRACKING (x_k vs z_k vs TRUE OFFSET)',
          subtitle:
              'Kalman posterior DC estimate smoothing noisy block-mean observations.',
          traces: [
            ChartTrace(
              label: 'Raw z_k',
              values: [for (final s in hist) s.rawMeasurementZ],
              color: kMuted.withValues(alpha: 0.7),
              strokeWidth: 1.3,
            ),
            if (hist.any((s) => s.trueStateOffset != null))
              ChartTrace(
                label: 'True DC',
                values: [for (final s in hist) s.trueStateOffset],
                color: kAmber,
                strokeWidth: 1.6,
                dashed: true,
              ),
            ChartTrace(
              label: 'Kalman x_k',
              values: [for (final s in hist) s.stateEstimateX],
              color: kMint,
              strokeWidth: 2.5,
            ),
          ],
        ),
        const SizedBox(height: 12),
        MultiSeriesChartCard(
          title: 'RICCATI GAIN (K_k) & ERROR COVARIANCE (P_k)',
          subtitle:
              'Convergence of dynamic Kalman gain K_k toward algebraic steady-state K_∞.',
          traces: [
            ChartTrace(
              label: 'Gain K_k',
              values: [for (final s in hist) s.kalmanGainK],
              color: kBlue,
              strokeWidth: 2.2,
            ),
            ChartTrace(
              label: 'Steady K_∞',
              values: [for (final s in hist) s.steadyStateGain],
              color: kViolet,
              strokeWidth: 1.5,
              dashed: true,
            ),
            ChartTrace(
              label: 'Posterior P_k',
              values: [for (final s in hist) s.posteriorCovarianceP],
              color: kMint,
              strokeWidth: 1.8,
            ),
          ],
        ),
        const SizedBox(height: 12),
        MultiSeriesChartCard(
          title: 'INNOVATION RESIDUAL (ỹ_k) & ±2√S_k CONSISTENCY ENVELOPE',
          subtitle:
              '95% Gaussian innovation bounds; excursions signal unmodeled state jumps.',
          symmetricZero: true,
          traces: [
            ChartTrace(
              label: '+2√S_k',
              values: [for (final s in hist) s.innovationBound95],
              color: kAmber.withValues(alpha: 0.75),
              strokeWidth: 1.3,
              dashed: true,
            ),
            ChartTrace(
              label: '-2√S_k',
              values: [for (final s in hist) -s.innovationBound95],
              color: kAmber.withValues(alpha: 0.75),
              strokeWidth: 1.3,
              dashed: true,
            ),
            ChartTrace(
              label: 'Innovation ỹ_k',
              values: [for (final s in hist) s.innovationY],
              color: kRose,
              strokeWidth: 2.0,
            ),
          ],
        ),
        const SizedBox(height: 12),
        MultiSeriesChartCard(
          title: 'CHANNEL SNR (dB), TRACKING RATIO (100·ρ) & BER (%)',
          subtitle:
              'Physical BPSK link quality alongside adaptive Q/R ratio decisions.',
          traces: [
            ChartTrace(
              label: 'SNR (dB)',
              values: [for (final s in hist) s.snrDb],
              color: kMint,
              strokeWidth: 2.0,
            ),
            ChartTrace(
              label: '100 · ρ',
              values: [for (final s in hist) s.trackingRatioRho * 100.0],
              color: kViolet,
              strokeWidth: 1.8,
            ),
            ChartTrace(
              label: 'BER (%)',
              values: [
                for (final s in hist) s.ber == null ? null : s.ber! * 100.0,
              ],
              color: kRose,
              strokeWidth: 1.8,
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// TAB 3: INTERACTIVE ON-DEVICE KALMAN WORKBENCH
// =============================================================================

class _OnDeviceWorkbenchTab extends StatelessWidget {
  const _OnDeviceWorkbenchTab({required this.controller});
  final TelemetryController controller;

  @override
  Widget build(BuildContext context) {
    final wb = controller.workbench;
    final snap = controller.latest;
    final logQ =
        (snap.processNoiseQ > 0
                ? (snap.processNoiseQ.clamp(1e-5, 1.0))
                : 0.0067)
            .toDouble();

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _PanelBox(
          title: 'SIGNAL & SENSOR STREAM PROFILE',
          icon: Icons.waves_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in SimulationProfile.values)
                    ChoiceChip(
                      key: Key('profile-chip-${p.name}'),
                      label: Text(p.title),
                      selected: wb.profile == p,
                      onSelected: (_) => controller.setSimulationProfile(p),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                wb.profile.subtitle,
                style: const TextStyle(color: kMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    key: const Key('step-once-btn'),
                    onPressed: controller.stepSingleFrame,
                    icon: const Icon(Icons.skip_next_rounded, size: 18),
                    label: const Text('Single Step'),
                  ),
                  FilledButton.tonalIcon(
                    key: const Key('inject-step-btn'),
                    onPressed: () => controller.injectDisturbance(0.65),
                    icon: const Icon(Icons.bolt_rounded, size: 18),
                    label: const Text('+0.65 V Step Impulse'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('reset-kalman-btn'),
                    onPressed: controller.resetOnDeviceFilter,
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('Reset State'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _PanelBox(
          title: 'KALMAN COVARIANCE TUNING (Q, R, ρ)',
          icon: Icons.tune_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Adaptive Rule Policy (R = σ̂², Q = 0.0268 · R)',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Disable to tune Process Q and Measurement R manually.',
                  style: TextStyle(color: kMuted, fontSize: 11.5),
                ),
                value: wb.autoRuleAdaptation,
                onChanged: controller.setAutoRuleAdaptation,
              ),
              _LabeledSlider(
                label: 'Process Noise Q',
                valueText: snap.processNoiseQ.toStringAsFixed(5),
                value: logQ.clamp(0.0001, 0.25),
                min: 0.0001,
                max: 0.25,
                onChanged: (v) => controller.setManualKalmanQR(
                  q: v,
                  r: snap.measurementNoiseR,
                ),
              ),
              _LabeledSlider(
                label: 'Measurement Noise R',
                valueText: snap.measurementNoiseR.toStringAsFixed(4),
                value: snap.measurementNoiseR.clamp(0.01, 2.5),
                min: 0.01,
                max: 2.5,
                onChanged: (v) => controller.setManualKalmanQR(
                  q: snap.processNoiseQ,
                  r: v,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _PanelBox(
          title: 'CHANNEL IMPAIRMENTS (NOISE, DRIFT, FADING)',
          icon: Icons.equalizer_rounded,
          child: Column(
            children: [
              _LabeledSlider(
                label: 'AWGN Noise σ',
                valueText: '${wb.noiseStddev.toStringAsFixed(2)} V',
                value: wb.noiseStddev.clamp(0.05, 2.0),
                min: 0.05,
                max: 2.0,
                onChanged: (v) =>
                    controller.setChannelImpairments(noiseStddev: v),
              ),
              _LabeledSlider(
                label: 'DC Drift Walk σ_d',
                valueText: '${wb.driftStddev.toStringAsFixed(3)} V',
                value: wb.driftStddev.clamp(0.0, 0.08),
                min: 0.0,
                max: 0.08,
                onChanged: (v) =>
                    controller.setChannelImpairments(driftStddev: v),
              ),
              _LabeledSlider(
                label: 'Slow Fading Depth',
                valueText: '${(wb.fadingDepth * 100).toStringAsFixed(0)}%',
                value: wb.fadingDepth.clamp(0.0, 0.8),
                min: 0.0,
                max: 0.8,
                onChanged: (v) =>
                    controller.setChannelImpairments(fadingDepth: v),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// TAB 4: 3-NODE LIVE gRPC & HTTP TELEMETRY LINK
// =============================================================================

class _LiveThreeNodeLinkTab extends StatefulWidget {
  const _LiveThreeNodeLinkTab({required this.controller});
  final TelemetryController controller;

  @override
  State<_LiveThreeNodeLinkTab> createState() => _LiveThreeNodeLinkTabState();
}

class _LiveThreeNodeLinkTabState extends State<_LiveThreeNodeLinkTab> {
  late final TextEditingController _endpointCtrl;
  double _remoteQ = 0.0067;
  double _remoteR = 0.25;

  @override
  void initState() {
    super.initState();
    _endpointCtrl = TextEditingController(text: widget.controller.endpointUri);
  }

  @override
  void dispose() {
    _endpointCtrl.dispose();
    super.dispose();
  }

  Color _healthColor(lk.LinkStatus status) => switch (status) {
    lk.LinkStatus.connected => kMint,
    lk.LinkStatus.checking => kBlue,
    lk.LinkStatus.reconnecting => kAmber,
    lk.LinkStatus.connectionLost => kRose,
    lk.LinkStatus.serviceUnavailable => kRose,
  };

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    const roleNames = ['Sender (TX)', 'Receiver (RX)', 'Controller'];

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _PanelBox(
          title: 'TELEMETRY SOURCE & 3-NODE ENDPOINT',
          icon: Icons.settings_ethernet_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<TelemetrySourceMode>(
                segments: const [
                  ButtonSegment(
                    value: TelemetrySourceMode.onDeviceLab,
                    icon: Icon(Icons.smartphone_rounded, size: 18),
                    label: Text('On-Device Lab'),
                  ),
                  ButtonSegment(
                    value: TelemetrySourceMode.liveThreeNodeGrpc,
                    icon: Icon(Icons.cloud_sync_rounded, size: 18),
                    label: Text('3-Node Live gRPC'),
                  ),
                ],
                selected: {c.mode},
                onSelectionChanged: (sel) => c.setSourceMode(sel.first),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('live-endpoint-input'),
                controller: _endpointCtrl,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
                decoration: InputDecoration(
                  labelText: 'Controller gRPC / Cloudflare Tunnel URI',
                  helperText:
                      'Supports grpc:// (LAN Wi-Fi) & grpcs:// (TLS tunnel)',
                  filled: true,
                  fillColor: kBgInk,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                key: const Key('connect-live-btn'),
                onPressed: () =>
                    unawaited(c.connectLiveGrpc(_endpointCtrl.text)),
                icon: const Icon(Icons.link_rounded),
                label: const Text('Connect & Start 1 s NodeService Probes'),
              ),
              if (c.lastControlStatus != null) ...[
                const SizedBox(height: 8),
                Text(
                  c.lastControlStatus!,
                  style: const TextStyle(color: kAmber, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _PanelBox(
          title: 'THREE-LAPTOP TOPOLOGY HEALTH (gRPC NodeService)',
          icon: Icons.monitor_heart_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: _healthColor(c.nodeHealth[i].link),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          roleNames[i],
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '${c.nodeHealth[i].link.label} · ${c.nodeHealth[i].dataFlow.label}',
                        style: const TextStyle(color: kMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              const Divider(color: kLine, height: 20),
              Text(
                'TX → RX Stream: ${c.txToRxSummary}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final e in c.streamStatuses.entries)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kBgInk,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: kLine),
                      ),
                      child: Text(
                        '${e.key}: ${e.value}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: kMuted,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _PanelBox(
          title: 'REMOTE RECEIVER Q / R OVERRIDE (ApplyReceiverConfig)',
          icon: Icons.send_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LabeledSlider(
                label: 'Proposed Q',
                valueText: _remoteQ.toStringAsFixed(4),
                value: _remoteQ,
                min: 0.0005,
                max: 0.2,
                onChanged: (v) => setState(() => _remoteQ = v),
              ),
              _LabeledSlider(
                label: 'Proposed R',
                valueText: _remoteR.toStringAsFixed(3),
                value: _remoteR,
                min: 0.02,
                max: 2.0,
                onChanged: (v) => setState(() => _remoteR = v),
              ),
              OutlinedButton.icon(
                onPressed: () => unawaited(
                  c.applyRemoteReceiverConfig(
                    kalmanQ: _remoteQ,
                    kalmanR: _remoteR,
                  ),
                ),
                icon: const Icon(Icons.publish_rounded, size: 18),
                label: const Text('Dispatch Versioned RxConfig'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PanelBox extends StatelessWidget {
  const _PanelBox({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: kSurface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kLine),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: kMint),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kMuted, fontSize: 12.5)),
          Text(
            valueText,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
      Slider(
        value: value,
        min: min,
        max: max,
        onChanged: onChanged,
      ),
    ],
  );
}
