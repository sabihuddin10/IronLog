import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_spacing.dart';
import '../../core/theme_controller.dart';

Future<void> showCustomAccentPicker(BuildContext context) {
  final controller = context.read<ThemeController>();
  final start = controller.customAccent;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CustomAccentSheet(
      initialAccent: start?.accent ?? controller.activeAccent(Theme.of(context).brightness).accent,
      initialAccent2: start?.accent2 ?? controller.activeAccent(Theme.of(context).brightness).accent2,
    ),
  );
}

class _CustomAccentSheet extends StatefulWidget {
  const _CustomAccentSheet({required this.initialAccent, required this.initialAccent2});

  final Color initialAccent;
  final Color initialAccent2;

  @override
  State<_CustomAccentSheet> createState() => _CustomAccentSheetState();
}

class _CustomAccentSheetState extends State<_CustomAccentSheet> {
  late Color _accent = widget.initialAccent;
  late Color _accent2 = widget.initialAccent2;
  int _editing = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_accent, _accent2]),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Color 1')),
                ButtonSegment(value: 1, label: Text('Color 2')),
              ],
              selected: {_editing},
              onSelectionChanged: (s) => setState(() => _editing = s.first),
            ),
            const SizedBox(height: AppSpacing.md),
            ColorPicker(
              pickerColor: _editing == 0 ? _accent : _accent2,
              onColorChanged: (c) => setState(() {
                if (_editing == 0) {
                  _accent = c;
                } else {
                  _accent2 = c;
                }
              }),
              enableAlpha: false,
              labelTypes: const [ColorLabelType.rgb, ColorLabelType.hex],
              pickerAreaHeightPercent: 0.6,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () {
                context.read<ThemeController>().setCustomAccent(_accent, _accent2);
                Navigator.of(context).pop();
              },
              child: const Text('Use this accent'),
            ),
          ],
        ),
      ),
    );
  }
}
