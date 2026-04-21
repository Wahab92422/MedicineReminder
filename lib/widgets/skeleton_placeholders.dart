import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_spacing.dart';

/// Shimmer colors derived from the current theme.
class _SkeletonColors {
  _SkeletonColors(this.scheme);

  final ColorScheme scheme;

  Color get base =>
      scheme.surfaceContainerHighest.withValues(alpha: 0.55);
  Color get highlight =>
      scheme.surfaceContainerHigh.withValues(alpha: 0.92);
}

/// Non-scrollable column of skeleton cards (e.g. inside [SingleChildScrollView]).
class InventoryListLoadingSkeleton extends StatelessWidget {
  const InventoryListLoadingSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final c = _SkeletonColors(Theme.of(context).colorScheme);
    return Shimmer.fromColors(
      baseColor: c.base,
      highlightColor: c.highlight,
      child: Column(
        children: List.generate(
          itemCount,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: _SkeletonListCard(),
          ),
        ),
      ),
    );
  }
}

/// Scrollable list of placeholder cards (initial data load).
class ListLoadingSkeleton extends StatelessWidget {
  const ListLoadingSkeleton({
    super.key,
    this.itemCount = 6,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.md,
      0,
      AppSpacing.md,
      88,
    ),
    this.showOverviewPlaceholder = false,
  });

  final int itemCount;
  final EdgeInsetsGeometry padding;
  /// When true, draws a block above the list (matches screens with an overview card).
  final bool showOverviewPlaceholder;

  @override
  Widget build(BuildContext context) {
    final c = _SkeletonColors(Theme.of(context).colorScheme);

    return Shimmer.fromColors(
      baseColor: c.base,
      highlightColor: c.highlight,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: [
          if (showOverviewPlaceholder) ...[
            const _SkeletonOverviewBlock(),
            const SizedBox(height: AppSpacing.sm),
          ],
          ...List.generate(
            itemCount,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: _SkeletonListCard(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer bar used at the bottom of lists while loading the next page.
class SkeletonLoadMoreFooter extends StatelessWidget {
  const SkeletonLoadMoreFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final c = _SkeletonColors(Theme.of(context).colorScheme);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Shimmer.fromColors(
        baseColor: c.base,
        highlightColor: c.highlight,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    );
  }
}

/// Compact shimmer for form dropdown / async field areas.
class InlineFormSkeleton extends StatelessWidget {
  const InlineFormSkeleton({super.key, this.lines = 4});

  final int lines;

  @override
  Widget build(BuildContext context) {
    final c = _SkeletonColors(Theme.of(context).colorScheme);
    return Shimmer.fromColors(
      baseColor: c.base,
      highlightColor: c.highlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(
          lines,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: i == lines - 1 ? 0 : AppSpacing.md),
            child: Container(
              height: i == 0 ? 52 : 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Centered shimmer for auth / bootstrap (narrow layout).
class AuthLoadingSkeleton extends StatelessWidget {
  const AuthLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = _SkeletonColors(Theme.of(context).colorScheme);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Shimmer.fromColors(
          baseColor: c.base,
          highlightColor: c.highlight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                height: 14,
                width: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                height: 12,
                width: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonOverviewBlock extends StatelessWidget {
  const _SkeletonOverviewBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 18,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 14,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            height: 14,
            width: 260,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonListCard extends StatelessWidget {
  const _SkeletonListCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 18,
                      width: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      height: 13,
                      width: 220,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 72,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
        ],
      ),
    );
  }
}
