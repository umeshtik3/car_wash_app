import 'package:flutter/material.dart';
import 'package:car_wash_app/app_theme/app_theme.dart';
import 'package:car_wash_app/app_theme/components.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? _selectedMethod; // 'upi' | 'card' | 'wallet' | 'cash'

  void _select(String method) {
    setState(() { _selectedMethod = method; });
  }

  Widget _buildSummary() {
    final List<_SummaryRow> services = const <_SummaryRow>[
      _SummaryRow(label: 'Basic Wash', value: '\$49.99'),
      _SummaryRow(label: 'Interior Clean', value: '\$19.99'),
    ];
    const String dateStr = '—';
    const String timeStr = '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final _SummaryRow row in services)
          Row(children: [Text(row.label), const Spacer(), Text(row.value)]),
        Row(children: const [Text('Date'), Spacer(), Text(dateStr)]),
        Row(children: const [Text('Time'), Spacer(), Text(timeStr)]),
        Row(children: const [
          Text('Total', style: TextStyle(fontWeight: FontWeight.w600)),
          Spacer(),
          Text('\$69.98', style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  child: Text('Payment', style: context.text.titleLarge),
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
                      Text('Choose payment method', style: context.text.bodySmall),
                      const SizedBox(height: AppSpacing.sm),
                      Column(children: [
                        _PayMethodTile(
                          label: 'UPI',
                          subtitle: 'Pay via UPI apps',
                          selected: _selectedMethod == 'upi',
                          onTap: () => _select('upi'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _PayMethodTile(
                          label: 'Card',
                          subtitle: 'Visa/Mastercard',
                          selected: _selectedMethod == 'card',
                          onTap: () => _select('card'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _PayMethodTile(
                          label: 'Wallet',
                          subtitle: 'Popular wallets',
                          selected: _selectedMethod == 'wallet',
                          onTap: () => _select('wallet'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _PayMethodTile(
                          label: 'Cash',
                          subtitle: 'Pay at service time',
                          selected: _selectedMethod == 'cash',
                          onTap: () => _select('cash'),
                        ),
                      ]),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppButton(label: 'Back', primary: false, onPressed: () => Navigator.of(context).pop()),
                          AppButton(
                            label: 'Pay now',
                            primary: true,
                            onPressed: _selectedMethod == null ? null : () {
                              Navigator.of(context).pushNamed('/confirmation');
                            },
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

class _PayMethodTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PayMethodTile({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.medium,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: AppRadii.medium,
          border: Border.all(color: selected ? AppColors.primary : Theme.of(context).dividerColor),
          boxShadow: selected ? <BoxShadow>[BoxShadow(color: AppColors.primary.withValues(alpha:0.06), spreadRadius: 2)] : AppShadows.small,
        ),
        child: Row(
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: context.text.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle, style: context.text.bodySmall),
            ])),
            if (selected) Icon(Icons.check_circle, color: AppColors.primary),
          ],
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


