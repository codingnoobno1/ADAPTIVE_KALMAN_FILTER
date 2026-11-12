import 'package:flutter/material.dart';

import '../models/kalman_parameters.dart';

const Color kBgInk = Color(0xff071116);
const Color kSurface = Color(0xff0d1a21);
const Color kSurfaceHigh = Color(0xff132630);
const Color kLine = Color(0xff213844);
const Color kMuted = Color(0xff8fa6b2);
const Color kMint = Color(0xff58f3c2);
const Color kAmber = Color(0xffffd166);
const Color kBlue = Color(0xff74a9ff);
const Color kRose = Color(0xffff7b9c);
const Color kViolet = Color(0xffb68cff);

Color provenanceColor(ValueProvenance p) => switch (p) {
  ValueProvenance.directMeasurement => kMint,
  ValueProvenance.riccatiDerived => kBlue,
  ValueProvenance.mlPredicted => kViolet,
  ValueProvenance.unavailable => kMuted,
};

/// Compact scientific card displaying one Kalman/channel parameter. Tapping
/// opens a bottom sheet with the exact mathematical equation and provenance.
class ParameterMetricTile extends StatelessWidget {
  const ParameterMetricTile({
    super.key,
    required this.descriptor,
    this.onTap,
  });

  final ParameterDescriptor descriptor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = descriptor.healthy == null
        ? provenanceColor(descriptor.provenance)
        : (descriptor.healthy! ? kMint : kAmber);

    return Material(
      color: kSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: Key('param-tile-${descriptor.id}'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap ?? () => showParameterFormulaSheet(context, descriptor),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kLine),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        descriptor.symbol,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: kSurfaceHigh,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      descriptor.provenance.badge,
                      style: TextStyle(
                        color: provenanceColor(descriptor.provenance),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                '${descriptor.formattedValue}${descriptor.formattedValue == '—' ? '' : descriptor.unit}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                descriptor.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (descriptor.note != null) ...[
                const SizedBox(height: 4),
                Text(
                  descriptor.note!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: statusColor.withValues(alpha: 0.85),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal bottom sheet showing full mathematical equation, provenance, and
/// live numeric interpretation for any parameter.
void showParameterFormulaSheet(
  BuildContext context,
  ParameterDescriptor descriptor,
) {
  final badgeColor = provenanceColor(descriptor.provenance);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: kSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  descriptor.symbol,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    descriptor.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    descriptor.provenance.badge,
                    style: TextStyle(color: badgeColor, fontSize: 11),
                  ),
                  backgroundColor: kSurfaceHigh,
                  side: BorderSide(color: badgeColor.withValues(alpha: 0.4)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kBgInk,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kLine),
              ),
              child: Text(
                descriptor.formula,
                style: const TextStyle(
                  color: kMint,
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              descriptor.description,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text(
                  'Current Reading: ',
                  style: TextStyle(color: kMuted, fontSize: 13),
                ),
                Text(
                  '${descriptor.formattedValue}${descriptor.formattedValue == '—' ? '' : descriptor.unit}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            if (descriptor.note != null) ...[
              const SizedBox(height: 6),
              Text(
                descriptor.note!,
                style: const TextStyle(color: kAmber, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
