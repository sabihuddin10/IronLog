import 'package:flutter/material.dart';
import '../../../data/body_profile_store.dart';

class UnitPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const UnitPill({required this.label, required this.selected, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: selected ? scheme.primary : scheme.surfaceContainerHighest,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class GenderPicker extends StatelessWidget {
  final Gender value;
  final ValueChanged<Gender> onChanged;

  const GenderPicker({required this.value, required this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        InkWell(
          onTap: () => onChanged(Gender.male),
          borderRadius: BorderRadius.circular(20),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: value == Gender.male ? scheme.primary : scheme.surfaceContainerHighest,
            child: Icon(Icons.male,
                color: value == Gender.male ? scheme.onPrimary : scheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => onChanged(Gender.female),
          borderRadius: BorderRadius.circular(20),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: value == Gender.female ? scheme.primary : scheme.surfaceContainerHighest,
            child: Icon(Icons.female,
                color: value == Gender.female ? scheme.onPrimary : scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class LabeledField extends StatelessWidget {
  final String label;
  final Widget field;
  final Widget? trailing;

  const LabeledField({required this.label, required this.field, this.trailing, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 70, child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
          const SizedBox(width: 10),
          Expanded(child: field),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class UnderlineNumberField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const UnderlineNumberField({required this.controller, this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      decoration: const InputDecoration(
        isDense: true,
        border: UnderlineInputBorder(),
      ),
    );
  }
}

class ResultBanner extends StatelessWidget {
  final Widget child;
  final Color? color;

  const ResultBanner({required this.child, this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color ?? Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
        child: child,
      ),
    );
  }
}

class CalculatorScaffold extends StatelessWidget {
  final String title;
  final String description;
  final List<Widget> children;
  final VoidCallback? onReset;

  const CalculatorScaffold({
    required this.title,
    required this.description,
    required this.children,
    this.onReset,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (onReset != null)
            IconButton(icon: const Icon(Icons.refresh), onPressed: onReset),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(description, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
