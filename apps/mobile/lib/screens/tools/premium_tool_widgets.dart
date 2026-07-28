import 'package:flutter/material.dart';
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
      backgroundColor: Premium.bg,
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
                      color: Premium.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Premium.border),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, size: 15, color: Premium.textDim),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(title, style: Premium.heading(19))),
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
          style: Premium.body(12.5, color: Premium.textDim).copyWith(height: 1.6),
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
          SizedBox(width: 64, child: Text(label, style: Premium.body(13.5, weight: FontWeight.w600, color: Premium.text))),
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
      style: Premium.body(16, weight: FontWeight.w600, color: Premium.text),
      cursorColor: Premium.accent,
      decoration: const InputDecoration(
        isDense: true,
        filled: false,
        contentPadding: EdgeInsets.only(bottom: 8, top: 4),
        border: UnderlineInputBorder(borderSide: BorderSide(color: Premium.borderStrong, width: 1.5)),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Premium.borderStrong, width: 1.5)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Premium.accent, width: 1.5)),
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
          gradient: selected ? Premium.accentGradient : null,
          color: selected ? null : Premium.surface3,
          border: selected ? null : Border.all(color: Premium.border),
          boxShadow: selected ? Premium.accentGlowShadow(blur: 12, spread: -4) : null,
        ),
        child: Text(
          glyph,
          style: Premium.body(14, weight: FontWeight.w700, color: selected ? Premium.ink : Premium.textFaint),
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
          gradient: selected ? Premium.accentGradient : null,
          color: selected ? null : Premium.surface3,
          border: selected ? null : Border.all(color: Premium.border),
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected ? Premium.accentGlowShadow(blur: 12, spread: -4) : null,
        ),
        child: Text(
          label,
          style: Premium.body(10.5, weight: FontWeight.w700, color: selected ? Premium.ink : Premium.textFaint)
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
          Text(label, style: Premium.body(13.5, weight: FontWeight.w600, color: Premium.text)),
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
                      color: Premium.surface2,
                      border: Border.all(color: Premium.border),
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
                            style: Premium.body(12.5, weight: FontWeight.w500, color: Premium.textDim),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.keyboard_arrow_down, size: 14, color: Premium.textFaint),
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
    backgroundColor: Premium.surface2,
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
                child: Align(alignment: Alignment.centerLeft, child: Text(title, style: Premium.heading(15))),
              ),
              for (final option in options)
                ListTile(
                  title: Text(labelOf(option), style: Premium.body(14, weight: FontWeight.w500, color: Premium.text)),
                  trailing: option == selected ? const Icon(Icons.check, color: Premium.accent) : null,
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
        gradient: Premium.accentGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: Premium.accentGlowShadow(blur: 26, spread: -12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [_block(leftLabel, leftValue), _block(rightLabel, rightValue)],
      ),
    );
  }

  Widget _block(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Premium.body(10, weight: FontWeight.w700, color: Premium.ink.withValues(alpha: 0.65))
              .copyWith(letterSpacing: 0.7),
        ),
        const SizedBox(height: 2),
        Text(value, style: Premium.heading(22, weight: FontWeight.w700, color: Premium.ink)),
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
        gradient: Premium.accentGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: Premium.accentGlowShadow(blur: 26, spread: -12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: Premium.heading(22, weight: FontWeight.w700, color: Premium.ink)),
          const SizedBox(height: 4),
          Text(subtitle, style: Premium.body(11.5, weight: FontWeight.w600, color: Premium.ink.withValues(alpha: 0.75))),
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
        color: Premium.surface2,
        border: Border.all(color: Premium.border),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [for (var i = 0; i < rows.length; i++) _row(rows[i], isLast: i == rows.length - 1)],
      ),
    );
  }

  Widget _row(PremiumCatRowData data, {required bool isLast}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: data.active
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Premium.accentDim, Premium.accent2.withValues(alpha: 0.08)],
              )
            : null,
        border: Border(
          bottom: isLast ? BorderSide.none : const BorderSide(color: Premium.border),
          left: BorderSide(color: data.active ? Premium.accent : Colors.transparent, width: 3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              data.label,
              overflow: TextOverflow.ellipsis,
              style: Premium.body(12.5, weight: data.active ? FontWeight.w700 : FontWeight.w500, color: data.active ? Premium.text : Premium.textDim),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            data.value,
            style: Premium.body(12.5, weight: FontWeight.w600, color: data.active ? Premium.accent : Premium.textFaint),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Premium.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          top: const BorderSide(color: Premium.border),
          right: const BorderSide(color: Premium.border),
          bottom: const BorderSide(color: Premium.border),
          left: const BorderSide(color: Premium.accent2, width: 3),
        ),
      ),
      child: Text(text, style: Premium.body(12, weight: FontWeight.w500, color: Premium.textDim).copyWith(height: 1.55)),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        gradient: Premium.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          top: const BorderSide(color: Premium.border),
          right: const BorderSide(color: Premium.border),
          bottom: const BorderSide(color: Premium.border),
          left: const BorderSide(color: Premium.accent2, width: 3),
        ),
      ),
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
                  style: Premium.heading(14.5, weight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Text('${profile.weightKg.toStringAsFixed(1)} kg', style: Premium.body(13, weight: FontWeight.w600, color: Premium.textDim)),
            ],
          ),
          const SizedBox(height: 7),
          Text(HealthFormulas.bmiAdvice(result.bmi), style: Premium.body(11.5, color: Premium.textDim).copyWith(height: 1.55)),
        ],
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
        gradient: Premium.cardGradient,
        border: Border.all(color: Premium.border),
        borderRadius: BorderRadius.circular(18),
        boxShadow: Premium.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: Premium.body(11, weight: FontWeight.w700, color: Premium.textFaint).copyWith(letterSpacing: 0.6),
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
        color: Premium.surface3,
        border: Border.all(color: Premium.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              tag,
              style: Premium.body(10.5, weight: FontWeight.w700, color: Premium.textFaint).copyWith(letterSpacing: 0.5),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: Premium.body(16, weight: FontWeight.w700, color: Premium.text),
              cursorColor: Premium.accent,
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
            Text(unit!, style: Premium.body(11.5, weight: FontWeight.w600, color: Premium.textDim)),
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
          colors: [Premium.accentDim, Premium.accent2.withValues(alpha: 0.1)],
        ),
        border: Border.all(color: Premium.accent.withValues(alpha: 0.28)),
        boxShadow: Premium.accentGlowShadow(blur: 12, spread: -6),
      ),
      child: const Icon(Icons.swap_vert, size: 15, color: Premium.accent),
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
      children: [for (var i = 0; i < total; i++) _glass(filled: i < filled), _addTile()],
    );
  }

  Widget _glass({required bool filled}) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: filled ? Premium.accentGradient : null,
        color: filled ? null : Premium.surface3,
        border: filled ? null : Border.all(color: Premium.border),
        borderRadius: BorderRadius.circular(11),
        boxShadow: filled ? Premium.accentGlowShadow(blur: 12, spread: -4) : null,
      ),
      child: Icon(Icons.water_drop, size: 15, color: filled ? Premium.ink : Premium.textFaint),
    );
  }

  Widget _addTile() {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Premium.accent.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text('+', style: Premium.body(15, weight: FontWeight.w700, color: Premium.accent)),
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
