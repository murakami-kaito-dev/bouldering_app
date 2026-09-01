import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/terms_acceptance_provider.dart';
import '../components/common/app_logo.dart';
import '../theme/app_tokens.dart';
import '../../shared/utils/url_launcher_helper.dart';

/// 利用規約同意画面
///
/// 役割:
/// - App Store審査要件（Guideline 1.2）対応
/// - 初回起動時の利用規約同意取得
/// - 同意しないとアプリを使用できないゲート機能
///
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のView
/// - ユーザーインタラクションの管理
class TermsAgreementPage extends ConsumerStatefulWidget {
  const TermsAgreementPage({super.key});

  @override
  ConsumerState<TermsAgreementPage> createState() => _TermsAgreementPageState();
}

class _TermsAgreementPageState extends ConsumerState<TermsAgreementPage> {
  bool _isAgreed = false;

  @override
  Widget build(BuildContext context) {
    final termsState = ref.watch(termsAcceptanceProvider);

    return Scaffold(
      backgroundColor: AppColors.iwa,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // アプリロゴ
              const AppLogo(),
              const SizedBox(height: 40),

              // 説明文
              const Text(
                '利用規約をご確認の上、\n同意してください',
                style: TextStyle(
                  fontSize: 26,
                  color: AppColors.chalk,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // 利用規約リンク
              InkWell(
                onTap: () => UrlLauncherHelper.showTermsOfService(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    children: [
                      const Text(
                        '利用規約を開く',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.kabeBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 1,
                        width: 120,
                        color: AppColors.kabeBlue,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // チェックボックス
              Row(
                children: [
                  Checkbox(
                    value: _isAgreed,
                    onChanged: (value) {
                      setState(() {
                        _isAgreed = value ?? false;
                      });
                    },
                    activeColor: AppColors.kabeBlue,
                  ),
                  const Expanded(
                    child: Text(
                      '利用規約に同意します',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.chalk,
                      ),
                    ),
                  ),
                ],
              ),

              // 同意ボタン
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isAgreed && !termsState.isLoading
                      ? _handleAcceptTerms
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isAgreed ? AppColors.kabeBlue : AppColors.wareme,
                    foregroundColor: AppColors.onKabeBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: _isAgreed ? 2 : 0,
                  ),
                  child: termsState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.onKabeBlue,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '同意して始める',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // 注意書き
              Text(
                '※ 利用規約に同意いただかないと\nアプリをご利用いただけません',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.sunabokori,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 利用規約への同意処理
  Future<void> _handleAcceptTerms() async {
    try {
      await ref.read(termsAcceptanceProvider.notifier).acceptTerms();

      if (mounted) {
        // 同意完了後はメイン画面に自動遷移
        // app.dartで状態を監視して自動的に画面切り替えが行われる
      }
    } catch (e) {
      _showErrorSnackBar('同意の記録に失敗しました');
    }
  }

  /// エラーメッセージ表示
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.holdRed,
        ),
      );
    }
  }
}
