import 'package:flutter/material.dart';
import 'package:car_wash_app/app_theme/app_theme.dart';
import 'package:car_wash_app/app_theme/components.dart';

class SlotSelectionPage extends StatefulWidget {
  const SlotSelectionPage({super.key});

  @override
  State<SlotSelectionPage> createState() => _SlotSelectionPageState();
}

class _SlotSelectionPageState extends State<SlotSelectionPage> {
  DateTime? _selectedDate;
  String? _selectedTime;
  String? _dateError;
  String? _timeError;

  final List<String> _slots = const <String>[
    '09:00','10:00','11:00','12:00','13:00','14:00','15:00','16:00','17:00','18:00'
  ];

  String _formatDate(DateTime date) {
    return '${_pad(date.year, 4)}-${_pad(date.month)}-${_pad(date.day)}';
  }

  String _pad(int n, [int width = 2]) => n.toString().padLeft(width, '0');

  bool _isToday(DateTime date) {
    final DateTime now = DateTime.now();
    return now.year == date.year && now.month == date.month && now.day == date.day;
  }

  bool _isSlotDisabled(String time, DateTime forDate) {
    if (!_isToday(forDate)) return false;
    final DateTime now = DateTime.now();
    final List<String> parts = time.split(':');
    final int hour = int.parse(parts[0]);
    final int minute = int.parse(parts[1]);
    final DateTime slotDateTime = DateTime(forDate.year, forDate.month, forDate.day, hour, minute);
    return slotDateTime.isBefore(now) || slotDateTime.isAtSameMomentAs(now);
  }

  void _validateState() {
    final bool validDate = _selectedDate != null && !_selectedDate!.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
    final bool validTime = _selectedTime != null && _selectedTime!.isNotEmpty;
    setState(() {
      _dateError = validDate ? null : 'Please select a valid date.';
      _timeError = validTime ? null : 'Please select a time.';
    });
  }

  void _onPickDate() async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year, now.month, now.day);
    final DateTime lastDate = DateTime(now.year + 2);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null; // reset selection on date change
      });
      _validateState();
    }
  }

  Widget _buildSummary() {
    final List<_SummaryRow> selectedServices = const <_SummaryRow>[
      // Static demo entries; replace with actual state later
      _SummaryRow(label: 'Basic Wash', value: '49.99'),
      _SummaryRow(label: 'Interior Clean', value: '19.99'),
    ];
    final String dateStr = _selectedDate != null ? _selectedDate!.toLocal().toString().split(' ').first : '—';
    final String timeStr = _selectedTime ?? '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final _SummaryRow row in selectedServices)
          Row(children: [
            Text(row.label),
            const Spacer(),
            Text(row.value),
          ]),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [Text('Date'), const Spacer(), Text(dateStr)]),
        Row(children: [Text('Time'), const Spacer(), Text(timeStr)]),
        Row(children: [
          Text('Total', style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('69.98', style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String dateDisplay = _selectedDate != null ? _formatDate(_selectedDate!) : '';
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text('Select a slot', style: context.text.titleLarge),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Booking summary', style: context.text.headlineSmall),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: AppColors.border)),
                        ),
                        child: _buildSummary(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Choose date', style: context.text.bodySmall),
                        const SizedBox(height: AppSpacing.xs),
                        GestureDetector(
                          onTap: _onPickDate,
                          child: AbsorbPointer(
                            child: TextField(
                              controller: TextEditingController(text: dateDisplay),
                              decoration: InputDecoration(
                                hintText: 'Pick a date',
                                errorText: _dateError,
                                suffixIcon: const Icon(Icons.calendar_today),
                              ),
                            ),
                          ),
                        ),
                        if (_dateError != null) Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(_dateError!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                        ),
                      ]),
                      const SizedBox(height: AppSpacing.md),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Choose time', style: context.text.bodySmall),
                        const SizedBox(height: AppSpacing.xs),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: AppSpacing.sm,
                            mainAxisSpacing: AppSpacing.sm,
                            childAspectRatio: 2.8,
                          ),
                          itemCount: _slots.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String t = _slots[index];
                            final bool disabled = _selectedDate == null ? true : _isSlotDisabled(t, _selectedDate!);
                            final bool selected = t == _selectedTime;
                            return OutlinedButton(
                              onPressed: disabled ? null : () {
                                setState(() { _selectedTime = t; });
                                _validateState();
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: selected ? AppColors.primary : Theme.of(context).dividerColor),
                                shape: RoundedRectangleBorder(borderRadius: AppRadii.small),
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                                backgroundColor: selected ? AppColors.primary.withValues(alpha:0.02) : null,
                              ),
                              child: Text(t, style: TextStyle(color: disabled ? Theme.of(context).disabledColor : null)),
                            );
                          },
                        ),
                        if (_timeError != null) Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(_timeError!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                        ),
                      ]),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppButton(label: 'Back', primary: false, onPressed: () => Navigator.of(context).pop()),
                          AppButton(
                            label: 'Continue',
                            primary: true,
                            onPressed: (_selectedDate != null && _selectedTime != null) ? () => Navigator.of(context).pushNamed('/payment') : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});
}


