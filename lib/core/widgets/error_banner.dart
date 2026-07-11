import 'package:flutter/material.dart';

import '../network/api_exception.dart';
import '../theme/app_theme.dart';

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.message,
    required this.onRetry,
    this.fieldErrors,
  });

  final String message;
  final VoidCallback onRetry;
  final List<ApiFieldError>? fieldErrors;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.lightTokens;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.errorBannerBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tokens.errorBannerForegroundColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: tokens.errorBannerForegroundColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: tokens.errorBannerTextStyle),
                if (fieldErrors != null && fieldErrors!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${fieldErrors!.length} field issue${fieldErrors!.length == 1 ? '' : 's'}',
                    style: tokens.errorBannerTextStyle.copyWith(fontSize: 12),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
