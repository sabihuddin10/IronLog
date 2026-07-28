import 'package:flutter/material.dart';
import '../../core/premium_theme.dart';
import '../../core/premium_widgets.dart';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _formatLongDate(DateTime d) => '${_monthNames[d.month - 1]} ${d.day}, ${d.year}';

String _formatThousands(int n) {
  final s = n.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
    buffer.write(s[i]);
  }
  return buffer.toString();
}

class AgeCalculatorScreen extends StatefulWidget {
  const AgeCalculatorScreen({super.key});

  @override
  State<AgeCalculatorScreen> createState() => _AgeCalculatorScreenState();
}

class _AgeCalculatorScreenState extends State<AgeCalculatorScreen> {
  DateTime _birthDate = DateTime(DateTime.now().year - 23, DateTime.now().month, DateTime.now().day);
  DateTime _asOf = DateTime.now();

  Future<void> _pick(bool birth) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: birth ? _birthDate : _asOf,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => birth ? _birthDate = picked : _asOf = picked);
  }

  @override
  Widget build(BuildContext context) {
    var years = _asOf.year - _birthDate.year;
    var months = _asOf.month - _birthDate.month;
    var days = _asOf.day - _birthDate.day;
    if (days < 0) {
      months -= 1;
      final prevMonth = DateTime(_asOf.year, _asOf.month, 0);
      days += prevMonth.day;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }
    final totalDays = _asOf.difference(_birthDate).inDays;

    // Purely presentational addition for the grid2 stat card below — derived
    // from the same _birthDate/_asOf state, doesn't touch the verified
    // years/months/days/totalDays math above.
    final asOfDateOnly = DateTime(_asOf.year, _asOf.month, _asOf.day);
    var nextBirthday = DateTime(_asOf.year, _birthDate.month, _birthDate.day);
    if (!nextBirthday.isAfter(asOfDateOnly)) {
      nextBirthday = DateTime(_asOf.year + 1, _birthDate.month, _birthDate.day);
    }
    final daysToNextBirthday = nextBirthday.difference(asOfDateOnly).inDays;

    return Scaffold(
      backgroundColor: Premium.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            const _ScHeader(title: 'Age Calculator'),
            const _ScDesc('Enter your date of birth to see your exact age and time to your next birthday.'),
            Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Row(
                children: [
                  Expanded(child: _DateBox(label: 'Day', value: '${_birthDate.day}', onTap: () => _pick(true))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DateBox(
                      label: 'Month',
                      value: _birthDate.month.toString().padLeft(2, '0'),
                      onTap: () => _pick(true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _DateBox(label: 'Year', value: '${_birthDate.year}', onTap: () => _pick(true))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AS OF',
                    style: Premium.body(9.5, color: Premium.textFaint, weight: FontWeight.w700).copyWith(letterSpacing: 0.6),
                  ),
                  const SizedBox(height: 7),
                  InkWell(
                    onTap: () => _pick(false),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 13),
                      decoration: BoxDecoration(
                        color: Premium.surface3,
                        border: Border.all(color: Premium.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_asOf.year}-${_asOf.month.toString().padLeft(2, '0')}-${_asOf.day.toString().padLeft(2, '0')}',
                            style: Premium.body(15, color: Premium.text, weight: FontWeight.w600),
                          ),
                          const Icon(Icons.calendar_today_outlined, size: 15, color: Premium.textFaint),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 19),
              decoration: BoxDecoration(
                gradient: Premium.accentGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: Premium.accentGlowShadow(blur: 26, spread: -12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$years years, $months months, $days days',
                    style: Premium.heading(20, weight: FontWeight.w700, color: Premium.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'since ${_formatLongDate(_birthDate)}',
                    style: Premium.body(11.5, color: Premium.ink.withValues(alpha: 0.75), weight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.cake_outlined,
                    value: '$daysToNextBirthday',
                    label: 'Days to next birthday',
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: _StatCard(
                    icon: Icons.hourglass_bottom_outlined,
                    value: _formatThousands(totalDays),
                    label: 'Total days lived',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared sub-screen header — back chevron + title (`.sc-header`).
class _ScHeader extends StatelessWidget {
  final String title;
  const _ScHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Premium.surface2,
                border: Border.all(color: Premium.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back, size: 16, color: Premium.textDim),
            ),
          ),
          const SizedBox(width: 14),
          Text(title, style: Premium.heading(19)),
        ],
      ),
    );
  }
}

/// Descriptive paragraph under the header (`.sc-desc`).
class _ScDesc extends StatelessWidget {
  final String text;
  const _ScDesc(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Text(text, style: Premium.body(12.5, color: Premium.textDim).copyWith(height: 1.6)),
    );
  }
}

/// One boxed date cell (`.date-field` / `.input-box`) — tappable, opens the
/// same native date picker the screen already used.
class _DateBox extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _DateBox({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Premium.body(9.5, color: Premium.textFaint, weight: FontWeight.w700).copyWith(letterSpacing: 0.6),
        ),
        const SizedBox(height: 7),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
            decoration: BoxDecoration(
              color: Premium.surface3,
              border: Border.all(color: Premium.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(value, textAlign: TextAlign.center, style: Premium.body(15, color: Premium.text, weight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

/// One `grid2` stat card: icon chip, big value, small label below.
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      decoration: BoxDecoration(
        gradient: Premium.cardGradient,
        border: Border.all(color: Premium.border),
        borderRadius: BorderRadius.circular(18),
        boxShadow: Premium.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumIconChip(icon: icon, size: 32),
          const SizedBox(height: 13),
          Text(value, style: Premium.heading(20, weight: FontWeight.w600)),
          const SizedBox(height: 5),
          Text(label, style: Premium.body(12, color: Premium.textDim, weight: FontWeight.w500)),
        ],
      ),
    );
  }
}
