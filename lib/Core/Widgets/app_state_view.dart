import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum AppStateViewKind {
  loading,
  empty,
  error,
}

class AppStateView extends StatelessWidget {
  const AppStateView({
    super.key,
    required this.kind,
    this.title,
    this.message,
    this.icon,
    this.onRetry,
    this.retryLabel,
    this.color = Colors.black,
    this.padding = const EdgeInsets.all(24),
  });

  const AppStateView.loading({
    super.key,
    this.title,
    this.message,
    this.color = Colors.black,
    this.padding = const EdgeInsets.all(24),
  })  : kind = AppStateViewKind.loading,
        icon = null,
        onRetry = null,
        retryLabel = null;

  const AppStateView.empty({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.color = Colors.black,
    this.padding = const EdgeInsets.all(24),
  })  : kind = AppStateViewKind.empty,
        onRetry = null,
        retryLabel = null;

  const AppStateView.error({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.error_outline,
    this.onRetry,
    this.retryLabel,
    this.color = Colors.black,
    this.padding = const EdgeInsets.all(24),
  }) : kind = AppStateViewKind.error;

  final AppStateViewKind kind;
  final String? title;
  final String? message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final resolvedTitle = title ?? _defaultTitle;
    final resolvedMessage = message;

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (kind == AppStateViewKind.loading)
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: color,
                ),
              )
            else
              Icon(
                icon,
                color: color,
                size: 30,
              ),
            if (resolvedTitle.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                resolvedTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontFamily: 'MontserratMedium',
                ),
              ),
            ],
            if (resolvedMessage != null && resolvedMessage.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                resolvedMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              TextButton(
                onPressed: onRetry,
                child: Text(retryLabel ?? 'common.retry'.tr),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String get _defaultTitle {
    switch (kind) {
      case AppStateViewKind.loading:
        return 'common.loading'.tr;
      case AppStateViewKind.empty:
        return 'common.no_results'.tr;
      case AppStateViewKind.error:
        return 'common.error'.tr;
    }
  }
}
