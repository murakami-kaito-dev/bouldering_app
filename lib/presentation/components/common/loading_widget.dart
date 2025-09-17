import 'package:flutter/material.dart';

/// ローディング表示ウィジェット
/// 
/// 役割:
/// - 統一されたローディング表示
/// - メッセージ付きローディング
/// - サイズ調整可能なローディング
class LoadingWidget extends StatelessWidget {
  final String? message;
  final double? size;
  final Color? color;

  const LoadingWidget({
    super.key,
    this.message,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size ?? 32,
          height: size ?? 32,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? Theme.of(context).primaryColor,
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// インライン用の小さなローディングウィジェット
class InlineLoadingWidget extends StatelessWidget {
  final Color? color;

  const InlineLoadingWidget({
    super.key,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Colors.white,
        ),
      ),
    );
  }
}