/// Billing / marketing URL for the premium plan.
///
/// Pass at build time: `--dart-define=UPGRADE_PLAN_URL=https://example.com/pricing`
abstract final class UpgradeConfig {
  static const checkoutUrl = String.fromEnvironment(
    'UPGRADE_PLAN_URL',
    defaultValue: '',
  );
}
