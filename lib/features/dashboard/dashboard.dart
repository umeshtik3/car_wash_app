import 'package:flutter/material.dart';
import 'package:car_wash_app/app_theme/app_theme.dart';
import 'package:car_wash_app/app_theme/components.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _loading = true;
  List<_Service> _services = const <_Service>[];
  final Set<String> _selected = <String>{};

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    setState(() { _loading = true; });
    await Future<void>.delayed(const Duration(milliseconds: 800));
    setState(() {
      _loading = false;
      _services = const <_Service>[
        _Service(id: 'basic-wash', name: 'Basic Wash', price: 10, icon: 'W'),
        _Service(id: 'exterior-detailing', name: 'Exterior Detailing', price: 40, icon: 'D'),
        _Service(id: 'interior-clean', name: 'Interior Clean', price: 25, icon: 'I'),
        _Service(id: 'premium-full-detail', name: 'Premium Full Detail', price: 80, icon: 'P'),
      ];
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
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
                  child: Text('Services', style: context.text.titleLarge),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Choose a service', style: context.text.headlineSmall),
                      const SizedBox(height: AppSpacing.lg),
                      if (_loading) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                          ],
                        ),
                      ] else if (_services.isEmpty) ...[
                        Text('No services available.', style: context.text.bodySmall?.copyWith(color: Theme.of(context).hintColor)),
                      ] else ...[
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: AppSpacing.md,
                            crossAxisSpacing: AppSpacing.md,
                            childAspectRatio: 1.4,
                          ),
                          itemCount: _services.length,
                          itemBuilder: (BuildContext context, int index) {
                            final _Service s = _services[index];
                            final bool selected = _selected.contains(s.id);
                            return SelectableCard(
                              selected: selected,
                              onTap: () => _toggleSelect(s.id),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary,
                                      borderRadius: AppRadii.small,
                                    ),
                                    child: Text(s.icon, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(s.name, style: context.text.titleMedium),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text('4${s.price}', style: context.text.bodySmall),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text('Tap to select', style: context.text.bodySmall),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppButton(label: 'Log out', primary: false, onPressed: () => Navigator.of(context).pushReplacementNamed('/login')),
                          AppButton(label: 'Proceed to Booking', primary: true, onPressed: _selected.isEmpty ? null : () => Navigator.of(context).pushNamed('/slot-selection')),
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

class _Service {
  final String id;
  final String name;
  final int price;
  final String icon;
  const _Service({required this.id, required this.name, required this.price, required this.icon});
}


