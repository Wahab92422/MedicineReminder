import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/upgrade_config.dart';
import '../providers/payment_service_provider.dart';
import '../services/payment_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_header.dart';

class UpgradePlanScreen extends ConsumerStatefulWidget {
  const UpgradePlanScreen({super.key});

  @override
  ConsumerState<UpgradePlanScreen> createState() => _UpgradePlanScreenState();
}

class _UpgradePlanScreenState extends ConsumerState<UpgradePlanScreen> {
  static const _benefits = <_Benefit>[
    _Benefit(
      icon: Icons.notifications_active_rounded,
      title: 'Unlimited reminders',
      subtitle: 'Schedule as many medicine alerts as you need.',
    ),
    _Benefit(
      icon: Icons.insights_rounded,
      title: 'Full insights',
      subtitle: 'Deeper adherence stats and trends over time.',
    ),
    _Benefit(
      icon: Icons.support_agent_rounded,
      title: 'Priority support',
      subtitle: 'Get help faster when something needs attention.',
    ),
  ];

  bool _purchasing = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProduct());
  }

  Future<void> _loadProduct() async {
    final payment = ref.read(paymentServiceProvider);
    await payment.queryPremiumProduct();
    if (!mounted) return;
    setState(() => _statusMessage = payment.lastError.value);
  }

  Future<void> _onPurchase() async {
    final payment = ref.read(paymentServiceProvider);
    setState(() {
      _purchasing = true;
      _statusMessage = null;
    });

    final started = await payment.purchasePremium();
    if (!mounted) return;

    if (!started) {
      setState(() {
        _purchasing = false;
        _statusMessage = payment.lastError.value ?? 'Could not start purchase.';
      });
      return;
    }

    setState(() {
      _purchasing = false;
      _statusMessage =
          'Complete the purchase in the Play Store dialog. Your account updates when payment succeeds.';
    });
  }

  Future<void> _onWebFallback(BuildContext context) async {
    final raw = UpgradeConfig.checkoutUrl.trim();
    if (raw.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Web checkout not linked'),
          content: const Text(
            'Build with --dart-define=UPGRADE_PLAN_URL=https://… for an optional web fallback.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final uri = Uri.tryParse(raw);
    if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid upgrade link configuration.')),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the upgrade page.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final payment = ref.watch(paymentServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade plan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            color: AppColors.premiumContainer,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.workspace_premium_rounded, color: AppColors.premium, size: 40),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medicine Premium',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Subscribe with Google Play — product ID: ${PaymentService.premiumProductId}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.8),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'What you get'),
          const SizedBox(height: AppSpacing.sm),
          ..._benefits.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(b.icon, color: scheme.onPrimaryContainer),
                ),
                title: Text(b.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(b.subtitle),
              ),
            ),
          ),
          ValueListenableBuilder<String?>(
            valueListenable: payment.lastError,
            builder: (context, err, _) {
              if (err == null || err.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  err,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.error,
                      ),
                ),
              );
            },
          ),
          if (_statusMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                _statusMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          PrimaryButton(
            label: 'Subscribe with Google Play',
            icon: Icons.shopping_cart_checkout_rounded,
            isLoading: _purchasing,
            onPressed: _purchasing ? null : _onPurchase,
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
            onPressed: () => _onWebFallback(context),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Open web checkout (optional)'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'After a successful purchase, isPremium is set on your Firestore user document.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _Benefit {
  const _Benefit({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}
