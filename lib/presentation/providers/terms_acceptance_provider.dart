import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 利用規約同意状態
class TermsAcceptanceState {
  final bool hasAccepted;
  final String? acceptedVersion;
  final DateTime? acceptedDate;
  final bool isLoading;

  const TermsAcceptanceState({
    required this.hasAccepted,
    this.acceptedVersion,
    this.acceptedDate,
    this.isLoading = false,
  });

  TermsAcceptanceState copyWith({
    bool? hasAccepted,
    String? acceptedVersion,
    DateTime? acceptedDate,
    bool? isLoading,
  }) {
    return TermsAcceptanceState(
      hasAccepted: hasAccepted ?? this.hasAccepted,
      acceptedVersion: acceptedVersion ?? this.acceptedVersion,
      acceptedDate: acceptedDate ?? this.acceptedDate,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// 利用規約同意状態管理NotifierProvider（MVVM ViewModel）
/// 
/// 役割:
/// - 利用規約の同意状態管理
/// - SharedPreferencesでの永続化
/// - UI状態の提供
/// 
/// クリーンアーキテクチャにおける位置づけ:
/// - Presentation層のViewModel
/// - UIとビジネスロジックの仲介
class TermsAcceptanceNotifier extends StateNotifier<TermsAcceptanceState> {
  // 利用規約バージョン（規約更新時にインクリメント）
  static const String currentTermsVersion = '1.0.0';
  
  // SharedPreferencesキー
  static const String _termsAcceptedKey = 'terms_accepted';
  static const String _acceptedVersionKey = 'terms_accepted_version';
  static const String _acceptedDateKey = 'terms_accepted_date';

  SharedPreferences? _prefs;

  TermsAcceptanceNotifier() : super(const TermsAcceptanceState(hasAccepted: false, isLoading: true)) {
    _init();
  }

  /// 初期化：SharedPreferencesから現在の同意状態を読み込み
  Future<void> _init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadAcceptanceState();
    } catch (e) {
      // 初期化失敗時は未同意として扱う
      state = state.copyWith(isLoading: false, hasAccepted: false);
    }
  }

  /// 同意状態をSharedPreferencesから読み込み
  Future<void> _loadAcceptanceState() async {
    if (_prefs == null) return;

    final accepted = _prefs!.getBool(_termsAcceptedKey) ?? false;
    final acceptedVersion = _prefs!.getString(_acceptedVersionKey);
    final acceptedDateStr = _prefs!.getString(_acceptedDateKey);
    
    DateTime? acceptedDate;
    if (acceptedDateStr != null) {
      acceptedDate = DateTime.tryParse(acceptedDateStr);
    }

    // 同意済みかつ最新バージョンかチェック
    final hasAcceptedCurrent = accepted && acceptedVersion == currentTermsVersion;

    state = TermsAcceptanceState(
      hasAccepted: hasAcceptedCurrent,
      acceptedVersion: acceptedVersion,
      acceptedDate: acceptedDate,
      isLoading: false,
    );
  }

  /// 利用規約への同意を記録
  Future<void> acceptTerms() async {
    if (_prefs == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final now = DateTime.now();
      
      await _prefs!.setBool(_termsAcceptedKey, true);
      await _prefs!.setString(_acceptedVersionKey, currentTermsVersion);
      await _prefs!.setString(_acceptedDateKey, now.toIso8601String());

      state = TermsAcceptanceState(
        hasAccepted: true,
        acceptedVersion: currentTermsVersion,
        acceptedDate: now,
        isLoading: false,
      );
    } catch (e) {
      // エラー時は元の状態に戻す
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// 同意状態をリセット（テスト・デバッグ用）
  Future<void> resetAcceptance() async {
    if (_prefs == null) return;

    await _prefs!.remove(_termsAcceptedKey);
    await _prefs!.remove(_acceptedVersionKey);
    await _prefs!.remove(_acceptedDateKey);

    state = const TermsAcceptanceState(
      hasAccepted: false,
      isLoading: false,
    );
  }
}

/// 利用規約同意状態Provider
final termsAcceptanceProvider = StateNotifierProvider<TermsAcceptanceNotifier, TermsAcceptanceState>((ref) {
  return TermsAcceptanceNotifier();
});