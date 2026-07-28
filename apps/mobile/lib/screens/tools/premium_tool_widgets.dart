import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/premium_theme.dart';
import '../../data/body_profile_store.dart';
import '../../utils/health_formulas.dart';

/// Shared premium-styled building blocks for the BMI / BMR / Ideal Weight /
/// Water Intake calculator screens, replicating the shared visual patterns
/// (`.sc-header`, `.field-row`, `.pill-btn`, `.unit-pill`, `.select-row`,
/// `.result-banner`, `.cat-list`, `.info-banner`, `.convert-card`,
/// `.water-glasses`) from `app-redesign-premium.html`.
///
/// These widgets are purely presentational: every one that touches
/// [BodyProfileStore] or [HealthFormulas] calls the exact same
/// getters/setters/formulas the previous generic widgets did — no new
/// calculation or persistence logic lives here.

/// Screen shell: back-chevron header + title + description + body children,
/// replacing the generic `CalculatorScaffold` (AppBar + ListView) with the
/// spec's custom `.sc-header`/`.sc-desc` layout.
class ToolScreenScaffold extends StatelessWidget {
  final String title;
  final Widget description;
  final List<Widget> children;

  const ToolScreenScaffold({
    super.key,
    required this.title,
    required this.description,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.colors.cardBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: Icon(Icons.arrow_back_ios_new, size: 15, color: context.colors.textSecondary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(title, style: Premium.heading(context, 19))),
              ],
            ),
            const SizedBox(height: 16),
            description,
            ...children,
          ],
        ),
      ),
    );
  }
}

/// `.sc-desc` — descriptive paragraph below the header, supports bold
/// (`<b>`) inline segments via [InlineSpan]s.
class PremiumScDesc extends StatelessWidget {
  final List<InlineSpan> spans;

  const PremiumScDesc({super.key, required this.spans});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: RichText(
        text: TextSpan(
          style: Premium.body(context, 12.5, color: context.colors.textSecondary).copyWith(height: 1.6),
          children: spans,
        ),
      ),
    );
  }
}

/// `.field-row` — fixed-width label + flexible input area + trailing pill
/// group (gender pills or unit pills).
class PremiumFieldRow extends StatelessWidget {
  final String label;
  final Widget input;
  final Widget trailing;

  const PremiumFieldRow({super.key, required this.label, required this.input, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 64, child: Text(label, style: Premium.body(context, 13.5, weight: FontWeight.w600, color: context.colors.textPrimary))),
          const SizedBox(width: 14),
          Expanded(child: input),
          const SizedBox(width: 14),
          trailing,
        ],
      ),
    );
  }
}

/// `.field-row input.underline` — transparent, underline-only numeric input.
class PremiumUnderlineField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const PremiumUnderlineField({super.key, required this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      style: Premium.body(context, 16, weight: FontWeight.w600, color: context.colors.textPrimary),
      cursorColor: context.colors.accent,
      decoration: InputDecoration(
        isDense: true,
        filled: false,
        contentPadding: const EdgeInsets.only(bottom: 8, top: 4),
        border: UnderlineInputBorder(borderSide: BorderSide(color: context.colors.borderStrong, width: 1.5)),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.colors.borderStrong, width: 1.5)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.colors.accent, width: 1.5)),
      ),
    );
  }
}

/// `.pill-btn` — small circular glyph toggle (used for the ♂/♀ gender pills).
class PremiumPillGlyphButton extends StatelessWidget {
  final String glyph;
  final bool selected;
  final VoidCallback onTap;

  const PremiumPillGlyphButton({super.key, required this.glyph, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: selected ? context.colors.accentGradient : null,
          color: selected ? null : context.colors.surfaceHigh,
          border: selected ? null : Border.all(color: context.colors.border),
          boxShadow: selected ? context.colors.accentGlowShadow(blur: 12, spread: -4) : null,
        ),
        child: Text(
          glyph,
          style: Premium.body(context, 14, weight: FontWeight.w700, color: selected ? context.colors.onAccent : context.colors.textFaint),
        ),
      ),
    );
  }
}

/// Male/female pill pair driving [BodyProfileStore.setGender].
class PremiumGenderPillGroup extends StatelessWidget {
  final Gender value;
  final ValueChanged<Gender> onChanged;

  const PremiumGenderPillGroup({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PremiumPillGlyphButton(glyph: '♂', selected: value == Gender.male, onTap: () => onChanged(Gender.male)),
        const SizedBox(width: 8),
        PremiumPillGlyphButton(glyph: '♀', selected: value == Gender.female, onTap: () => onChanged(Gender.female)),
      ],
    );
  }
}

/// `.unit-pill` — rounded-rect unit toggle (KG/LBS, CM/FT, ...).
class PremiumUnitPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const PremiumUnitPill({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? context.colors.accentGradient : null,
          color: selected ? null : context.colors.surfaceHigh,
          border: selected ? null : Border.all(color: context.colors.border),
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected ? context.colors.accentGlowShadow(blur: 12, spread: -4) : null,
        ),
        child: Text(
          label,
          style: Premium.body(context, 10.5, weight: FontWeight.w700, color: selected ? context.colors.onAccent : context.colors.textFaint)
              .copyWith(letterSpacing: 0.3),
        ),
      ),
    );
  }
}

/// `.select-row` / `.select-box` — label + tappable trigger that opens
/// [showPremiumPicker].
class PremiumSelectRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const PremiumSelectRow({super.key, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        children: [
          Text(label, style: Premium.body(context, 13.5, weight: FontWeight.w600, color: context.colors.textPrimary)),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 190),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(11),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                    decoration: BoxDecoration(
                      color: context.colors.cardBackground,
                      border: Border.all(color: context.colors.border),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            value,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: Premium.body(context, 12.5, weight: FontWeight.w500, color: context.colors.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.keyboard_arrow_down, size: 14, color: context.colors.textFaint),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom-sheet picker used by [PremiumSelectRow] triggers.
Future<T?> showPremiumPicker<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required String Function(T) labelOf,
  required T selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: context.colors.cardBackground,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Align(alignment: Alignment.centerLeft, child: Text(title, style: Premium.heading(context, 15))),
              ),
              for (final option in options)
                ListTile(
                  title: Text(labelOf(option), style: Premium.body(context, 14, weight: FontWeight.w500, color: context.colors.textPrimary)),
                  trailing: option == selected ? Icon(Icons.check, color: context.colors.accent) : null,
                  onTap: () => Navigator.of(context).pop(option),
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// `.result-banner` two-value layout (BMI + Fat%).
class PremiumResultBannerPair extends StatelessWidget {
  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  const PremiumResultBannerPair({
    super.key,
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 17),
      decoration: BoxDecoration(
        gradient: context.colors.accentGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.colors.accentGlowShadow(blur: 26, spread: -12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [_block(context, leftLabel, leftValue), _block(context, rightLabel, rightValue)],
      ),
    );
  }

  Widget _block(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Premium.body(context, 10, weight: FontWeight.w700, color: context.colors.onAccent.withValues(alpha: 0.65))
              .copyWith(letterSpacing: 0.7),
        ),
        const SizedBox(height: 2),
        Text(value, style: Premium.heading(context, 22, weight: FontWeight.w700, color: context.colors.onAccent)),
      ],
    );
  }
}

/// `.result-banner.centered` — single big value + subtitle.
class PremiumResultBannerCentered extends StatelessWidget {
  final String value;
  final String subtitle;

  const PremiumResultBannerCentered({super.key, required this.value, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 17),
      decoration: BoxDecoration(
        gradient: context.colors.accentGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.colors.accentGlowShadow(blur: 26, spread: -12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: Premium.heading(context, 22, weight: FontWeight.w700, color: context.colors.onAccent)),
          const SizedBox(height: 4),
          Text(subtitle, style: Premium.body(context, 11.5, weight: FontWeight.w600, color: context.colors.onAccent.withValues(alpha: 0.75))),
        ],
      ),
    );
  }
}

class PremiumCatRowData {
  final String label;
  final String value;
  final bool active;

  const PremiumCatRowData({required this.label, required this.value, this.active = false});
}

/// `.cat-list` — rounded card of stacked rows, active row gets a gradient
/// tint + left accent stripe + bold text.
class PremiumCatList extends StatelessWidget {
  final List<PremiumCatRowData> rows;

  const PremiumCatList({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        border: Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [for (var i = 0; i < rows.length; i++) _row(context, rows[i], isLast: i == rows.length - 1)],
      ),
    );
  }

  Widget _row(BuildContext context, PremiumCatRowData data, {required bool isLast}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: data.active
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [context.colors.accentDim, context.colors.accent2.withValues(alpha: 0.08)],
              )
            : null,
        border: Border(
          bottom: isLast ? BorderSide.none : BorderSide(color: context.colors.border),
          left: BorderSide(color: data.active ? context.colors.accent : Colors.transparent, width: 3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              data.label,
              overflow: TextOverflow.ellipsis,
              style: Premium.body(context, 12.5, weight: data.active ? FontWeight.w700 : FontWeight.w500, color: data.active ? context.colors.textPrimary : context.colors.textSecondary),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            data.value,
            style: Premium.body(context, 12.5, weight: FontWeight.w600, color: data.active ? context.colors.accent : context.colors.textFaint),
          ),
        ],
      ),
    );
  }
}

/// `.info-banner` — accent-striped note box.
class PremiumInfoBanner extends StatelessWidget {
  final String text;

  const PremiumInfoBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    // A borderRadius requires uniform border-side colors in Flutter, so the
    // accent-colored left stripe can't be part of `border` alongside the
    // neutral other three sides (that combination throws at paint time,
    // silently dropping this widget's content) — it's a separate clipped
    // Container instead.
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: context.colors.accent2),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Text(
                  text,
                  style: Premium.body(context, 12, weight: FontWeight.w500, color: context.colors.textSecondary).copyWith(height: 1.55),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.bmi-inline` — compact always-visible BMI summary, replacing the old
/// `BmiSummaryCard`. Reuses the exact same [HealthFormulas.bmi] call (with
/// `useNewFormula: true`), [HealthFormulas.bmiCategoryLabel] and
/// [HealthFormulas.bmiAdvice] the previous widget used.
class PremiumBmiInline extends StatelessWidget {
  final BodyProfileStore profile;

  const PremiumBmiInline({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final result = HealthFormulas.bmi(profile.weightKg, profile.heightCm, profile.gender, profile.age, true);
    final category = HealthFormulas.bmiCategoryLabel(result.bmi);

    // Same fix as PremiumInfoBanner: a borderRadius requires uniform
    // border-side colors, so the accent left stripe is a separate clipped
    // Container rather than part of `border` — otherwise painting this
    // decoration throws and the whole card renders with no text.
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        gradient: context.colors.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: context.colors.accent2),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'BMI ${result.bmi.toStringAsFixed(1)} · $category',
                            overflow: TextOverflow.ellipsis,
                            style: Premium.heading(context, 14.5, weight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${profile.weightKg.toStringAsFixed(1)} kg',
                          style: Premium.body(context, 13, weight: FontWeight.w600, color: context.colors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      HealthFormulas.bmiAdvice(result.bmi),
                      style: Premium.body(context, 11.5, color: context.colors.textSecondary).copyWith(height: 1.55),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.convert-card` shell (label + stacked children).
class PremiumConvertCard extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const PremiumConvertCard({super.key, required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: context.colors.cardGradient,
        border: Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(18),
        boxShadow: Premium.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: Premium.body(context, 11, weight: FontWeight.w700, color: context.colors.textFaint).copyWith(letterSpacing: 0.6),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

/// `.convert-field` — tag + numeric input + optional unit suffix.
class PremiumConvertField extends StatelessWidget {
  final String tag;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String? unit;

  const PremiumConvertField({super.key, required this.tag, required this.controller, this.onChanged, this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.surfaceHigh,
        border: Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              tag,
              style: Premium.body(context, 10.5, weight: FontWeight.w700, color: context.colors.textFaint).copyWith(letterSpacing: 0.5),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: Premium.body(context, 16, weight: FontWeight.w700, color: context.colors.textPrimary),
              cursorColor: context.colors.accent,
              decoration: const InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (unit != null) ...[
            const SizedBox(width: 8),
            Text(unit!, style: Premium.body(context, 11.5, weight: FontWeight.w600, color: context.colors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

/// `.convert-swap-btn` — decorative swap icon between the two convert fields.
class PremiumConvertSwapIcon extends StatelessWidget {
  const PremiumConvertSwapIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.colors.accentDim, context.colors.accent2.withValues(alpha: 0.1)],
        ),
        border: Border.all(color: context.colors.accent.withValues(alpha: 0.28)),
        boxShadow: context.colors.accentGlowShadow(blur: 12, spread: -6),
      ),
      child: Icon(Icons.swap_vert, size: 15, color: context.colors.accent),
    );
  }
}

/// `.water-glasses` — wrap of glass tiles (filled vs outline) plus a
/// trailing decorative add tile. Purely presentational: there is no
/// persisted "glasses logged" state in the data layer, so [filled] should be
/// passed a caller-supplied value (0 unless/until such tracking exists).
class PremiumWaterGlasses extends StatelessWidget {
  final int total;
  final int filled;

  const PremiumWaterGlasses({super.key, required this.total, this.filled = 0});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: [for (var i = 0; i < total; i++) _glass(context, filled: i < filled), _addTile(context)],
    );
  }

  Widget _glass(BuildContext context, {required bool filled}) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: filled ? context.colors.accentGradient : null,
        color: filled ? null : context.colors.surfaceHigh,
        border: filled ? null : Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(11),
        boxShadow: filled ? context.colors.accentGlowShadow(blur: 12, spread: -4) : null,
      ),
      child: Icon(Icons.water_drop, size: 15, color: filled ? context.colors.onAccent : context.colors.textFaint),
    );
  }

  Widget _addTile(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.accent.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text('+', style: Premium.body(context, 15, weight: FontWeight.w700, color: context.colors.accent)),
    );
  }
}

/// `.field-row` for Age + gender pills, bound to [BodyProfileStore]. Mirrors
/// the old `AgeGenderRow`'s exact controller/setter logic.
class PremiumAgeGenderField extends StatefulWidget {
  final BodyProfileStore profile;

  const PremiumAgeGenderField({super.key, required this.profile});

  @override
  State<PremiumAgeGenderField> createState() => _PremiumAgeGenderFieldState();
}

class _PremiumAgeGenderFieldState extends State<PremiumAgeGenderField> {
  late final TextEditingController _controller = TextEditingController(text: '${widget.profile.age}');

  @override
  Widget build(BuildContext context) {
    return PremiumFieldRow(
      label: 'Age',
      input: PremiumUnderlineField(
        controller: _controller,
        onChanged: (v) {
          final age = int.tryParse(v);
          if (age != null) widget.profile.setAge(age);
        },
      ),
      trailing: PremiumGenderPillGroup(value: widget.profile.gender, onChanged: widget.profile.setGender),
    );
  }
}

/// `.field-row` for Weight + KG/LBS pills, bound to [BodyProfileStore].
/// Mirrors the old `WeightField`'s exact controller/setter logic.
class PremiumWeightField extends StatefulWidget {
  final BodyProfileStore profile;

  const PremiumWeightField({super.key, required this.profile});

  @override
  State<PremiumWeightField> createState() => _PremiumWeightFieldState();
}

class _PremiumWeightFieldState extends State<PremiumWeightField> {
  late final TextEditingController _controller = TextEditingController(
    text: (widget.profile.weightInLbs ? widget.profile.weightLbs : widget.profile.weightKg).toStringAsFixed(1),
  );

  void _refresh() {
    final value = widget.profile.weightInLbs ? widget.profile.weightLbs : widget.profile.weightKg;
    _controller.text = value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return PremiumFieldRow(
      label: 'Weight',
      input: PremiumUnderlineField(
        controller: _controller,
        onChanged: (v) {
          final value = double.tryParse(v);
          if (value == null) return;
          if (widget.profile.weightInLbs) {
            widget.profile.setWeightLbs(value);
          } else {
            widget.profile.setWeightKg(value);
          }
        },
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PremiumUnitPill(
            label: 'KG',
            selected: !widget.profile.weightInLbs,
            onTap: () {
              widget.profile.toggleWeightUnit(false);
              setState(_refresh);
            },
          ),
          const SizedBox(width: 6),
          PremiumUnitPill(
            label: 'LBS',
            selected: widget.profile.weightInLbs,
            onTap: () {
              widget.profile.toggleWeightUnit(true);
              setState(_refresh);
            },
          ),
        ],
      ),
    );
  }
}

/// `.field-row` for Height + CM/FT pills, bound to [BodyProfileStore].
/// Mirrors the old `HeightField`'s exact controller/setter logic.
class PremiumHeightField extends StatefulWidget {
  final BodyProfileStore profile;

  const PremiumHeightField({super.key, required this.profile});

  @override
  State<PremiumHeightField> createState() => _PremiumHeightFieldState();
}

class _PremiumHeightFieldState extends State<PremiumHeightField> {
  late final TextEditingController _cmController = TextEditingController(text: widget.profile.heightCm.toStringAsFixed(0));
  late final TextEditingController _ftController = TextEditingController(text: '${widget.profile.heightFeet}');
  late final TextEditingController _inController =
      TextEditingController(text: widget.profile.heightRemainderInches.toStringAsFixed(0));

  void _applyFtIn() {
    final ft = int.tryParse(_ftController.text) ?? 0;
    final inch = double.tryParse(_inController.text) ?? 0;
    widget.profile.setHeightFtIn(ft, inch);
  }

  @override
  Widget build(BuildContext context) {
    final ft = widget.profile.heightInFt;
    return PremiumFieldRow(
      label: 'Height',
      input: ft
          ? Row(
              children: [
                Expanded(child: PremiumUnderlineField(controller: _ftController, onChanged: (_) => _applyFtIn())),
                const SizedBox(width: 10),
                Expanded(child: PremiumUnderlineField(controller: _inController, onChanged: (_) => _applyFtIn())),
              ],
            )
          : PremiumUnderlineField(
              controller: _cmController,
              onChanged: (v) {
                final cm = double.tryParse(v);
                if (cm != null) widget.profile.setHeightCm(cm);
              },
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PremiumUnitPill(
            label: 'CM',
            selected: !ft,
            onTap: () {
              widget.profile.toggleHeightUnit(false);
              setState(() => _cmController.text = widget.profile.heightCm.toStringAsFixed(0));
            },
          ),
          const SizedBox(width: 6),
          PremiumUnitPill(
            label: 'FT',
            selected: ft,
            onTap: () {
              widget.profile.toggleHeightUnit(true);
              setState(() {
                _ftController.text = '${widget.profile.heightFeet}';
                _inController.text = widget.profile.heightRemainderInches.toStringAsFixed(0);
              });
            },
          ),
        ],
      ),
    );
  }
}
