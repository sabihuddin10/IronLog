import 'package:flutter/material.dart';
import '../../../data/body_profile_store.dart';
import 'profile_form_widgets.dart';

class AgeGenderRow extends StatefulWidget {
  final BodyProfileStore profile;
  const AgeGenderRow({required this.profile, super.key});

  @override
  State<AgeGenderRow> createState() => _AgeGenderRowState();
}

class _AgeGenderRowState extends State<AgeGenderRow> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.profile.age}');

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: 'Age',
      field: UnderlineNumberField(
        controller: _controller,
        onChanged: (v) {
          final age = int.tryParse(v);
          if (age != null) widget.profile.setAge(age);
        },
      ),
      trailing: GenderPicker(value: widget.profile.gender, onChanged: widget.profile.setGender),
    );
  }
}

class WeightField extends StatefulWidget {
  final BodyProfileStore profile;
  const WeightField({required this.profile, super.key});

  @override
  State<WeightField> createState() => _WeightFieldState();
}

class _WeightFieldState extends State<WeightField> {
  late final TextEditingController _controller = TextEditingController(
    text: (widget.profile.weightInLbs ? widget.profile.weightLbs : widget.profile.weightKg)
        .toStringAsFixed(1),
  );

  void _refresh() {
    final value = widget.profile.weightInLbs ? widget.profile.weightLbs : widget.profile.weightKg;
    _controller.text = value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: 'Weight',
      field: UnderlineNumberField(
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
          UnitPill(
            label: 'KG',
            selected: !widget.profile.weightInLbs,
            onTap: () {
              widget.profile.toggleWeightUnit(false);
              setState(_refresh);
            },
          ),
          const SizedBox(width: 6),
          UnitPill(
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

class HeightField extends StatefulWidget {
  final BodyProfileStore profile;
  const HeightField({required this.profile, super.key});

  @override
  State<HeightField> createState() => _HeightFieldState();
}

class _HeightFieldState extends State<HeightField> {
  late final TextEditingController _cmController =
      TextEditingController(text: widget.profile.heightCm.toStringAsFixed(0));
  late final TextEditingController _ftController =
      TextEditingController(text: '${widget.profile.heightFeet}');
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
    return LabeledField(
      label: 'Height',
      field: ft
          ? Row(
              children: [
                Expanded(child: UnderlineNumberField(controller: _ftController, onChanged: (_) => _applyFtIn())),
                const SizedBox(width: 8),
                Expanded(child: UnderlineNumberField(controller: _inController, onChanged: (_) => _applyFtIn())),
              ],
            )
          : UnderlineNumberField(
              controller: _cmController,
              onChanged: (v) {
                final cm = double.tryParse(v);
                if (cm != null) widget.profile.setHeightCm(cm);
              },
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UnitPill(
            label: 'CM',
            selected: !ft,
            onTap: () {
              widget.profile.toggleHeightUnit(false);
              setState(() => _cmController.text = widget.profile.heightCm.toStringAsFixed(0));
            },
          ),
          const SizedBox(width: 6),
          UnitPill(
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
