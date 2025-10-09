import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../components/common/app_logo.dart';
import '../providers/user_provider.dart';
import '../providers/statistics_provider.dart';
import '../pages/gym_selection_page.dart';
import '../providers/dependency_injection.dart';
import '../../shared/utils/image_url_validator.dart';
import '../providers/post_moderation_provider.dart';

/// ■ クラス
/// - View
/// - ボル活(ツイート)を投稿するページ
/// - StatefulWidget
/// - 状態：テキストの長さ、写真、ジム選択状態
class ActivityPostPage extends ConsumerStatefulWidget {
  // ツイートを編集するとき，すでにあるデータを受け取るための変数
  final Map<String, dynamic>? initialData;
  // ジム詳細ページから遷移したときのジムID
  final int? preSelectedGymId;
  // ジム詳細ページから遷移したかどうかのフラグ
  final bool fromGymDetail;

  const ActivityPostPage({
    Key? key,
    this.initialData,
    this.preSelectedGymId,
    this.fromGymDetail = false,
  }) : super(key: key);

  @override
  _ActivityPostPageState createState() => _ActivityPostPageState();
}

/// ■ クラス
/// - -View
/// - ボル活(ツイート)を投稿するページの状態を定義したもの
class _ActivityPostPageState extends ConsumerState<ActivityPostPage> {
  final TextEditingController _textController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? selectedGym;
  int? gymId;
  List<File> _mediaFiles = [];
  List<String> _uploadedUrls = [];
  FilePickerResult? result;

  // 編集時に利用する変数
  int? editingTweetId;
  bool isEditMode = false;
  String? originalText;
  DateTime? originalDate;
  List<String> originalUrls = [];

  // 投稿処理中か判定する変数
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();

    // 編集機能によって呼び出されたかを判定する
    final data = widget.initialData;
    if (data != null) {
      // 編集モード判定 trueへ変更
      isEditMode = true;
      editingTweetId = data['tweetId'];
      _textController.text = data['tweetContents'] ?? '';
      selectedGym = data['gymName'];
      gymId = int.tryParse(data['gymId'] ?? '');
      _selectedDate =
          DateTime.tryParse(data['visitedDate'] ?? '') ?? DateTime.now();
      // プレースホルダー画像を除外して有効な画像URLのみを保持
      final rawUrls = List<String>.from(data['mediaUrls'] ?? []);
      _uploadedUrls = ImageUrlValidator.filterValidImageUrls(rawUrls);
      originalText = _textController.text;
      originalDate = _selectedDate;
      originalUrls = List<String>.from(_uploadedUrls);
    } else if (widget.preSelectedGymId != null) {
      // ジム詳細ページから遷移した場合
      gymId = widget.preSelectedGymId;
      // ジム名は後でUseCaseから取得する
      _loadGymDetails();
    }
  }

  // ジム詳細情報を取得するメソッド
  Future<void> _loadGymDetails() async {
    if (gymId == null) return;

    try {
      final getGymDetailsUseCase = ref.read(getGymDetailsUseCaseProvider);
      final gym = await getGymDetailsUseCase.execute(gymId!);
      if (mounted && gym != null) {
        setState(() {
          selectedGym = gym.name;
        });
      }
    } catch (e) {
      // エラー時は何もしない（ジム選択画面で選択可能）
    }
  }

  /// ■ メソッド
  /// - GCS保存する写真を選択する
  Future<void> _pickMultipleImages() async {
    result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null && result!.files.isNotEmpty) {
      setState(() {
        final selectedFiles = result!.paths.map((path) => File(path!)).toList();

        // 現在の枚数(既存写真+追加写真)を合算
        int totalSelectedCount = _uploadedUrls.length + _mediaFiles.length;
        final availableSlots = 5 - totalSelectedCount;

        if (availableSlots <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('写真は最大5枚までです')),
          );
          return;
        }

        final filesToAdd = selectedFiles.take(availableSlots).toList();
        _mediaFiles.addAll(filesToAdd);

        if (filesToAdd.length < selectedFiles.length) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('写真は最大5枚までです')),
          );
        }
      });
    }
  }

  /// ■ メソッド
  /// - ジムを訪問した日を選択するメソッド
  Future<void> _selectDate(BuildContext context) async {
    final DateTime today = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: today,
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// ■ Widget build
  @override
  Widget build(BuildContext context) {
    final userAsyncValue = ref.watch(userProvider);

    return userAsyncValue.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => _buildUnloggedState(),
      data: (user) {
        if (user == null) {
          return _buildUnloggedState();
        } else {
          return _buildLoggedState(context, user);
        }
      },
    );
  }

  /// 未ログイン状態の表示
  Widget _buildUnloggedState() {
    return const Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 余白
          SizedBox(height: 128),

          // ロゴ
          Center(child: AppLogo()),
          SizedBox(height: 16),

          Text(
            'イワノボリタイに登録しよう',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF0056FF),
              fontSize: 20,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.50,
            ),
          ),
          SizedBox(height: 16),

          Text(
            'ログインして日々の\nボル活を投稿しよう！',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
              height: 1.4,
              letterSpacing: -0.50,
            ),
          ),
          SizedBox(height: 16),

          Text(
            'ジムで登った記録や\n感想を残しましょう！',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
              height: 1.4,
              letterSpacing: -0.50,
            ),
          ),
        ],
      ),
    );
  }

  /// ログイン状態の表示
  Widget _buildLoggedState(BuildContext context, user) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading:
            isEditMode || widget.fromGymDetail, // 編集時またはジム詳細からの遷移時に戻るボタンを表示
        title: Text(
          isEditMode ? 'ボル活編集' : 'ボル活投稿',
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFEF7FF),
        surfaceTintColor: const Color(0xFFFEF7FF),
        leading: (isEditMode || widget.fromGymDetail)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: [
          TextButton(
            onPressed: _isPosting
                ? null
                : () async {
                    // 投稿(編集)処理開始
                    setState(() => _isPosting = true);

                    // NGワードチェック
                    final moderationResult = ref.read(postModerationProvider.notifier)
                        .validateContent(_textController.text);
                    
                    if (!moderationResult.isAllowed) {
                      // NGワードが検出された場合
                      setState(() => _isPosting = false);
                      
                      if (mounted) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('投稿できません'),
                              content: Text(
                                '不適切な表現が含まれています。\n'
                                '検出された表現: ${moderationResult.firstDetectedWord}\n\n'
                                '投稿内容を修正してください。',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                      return; // 投稿処理を中断
                    }

                    // gymIdは既にGymSelectionPageから取得済み
                    if (gymId == null) {
                      // ジム選択を促すメッセージのSnackBarを表示
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ジムを選択してください')),
                      );
                    } else {
                      try {
                        final activityPostUseCase =
                            ref.read(activityPostUseCaseProvider);

                        if (isEditMode && editingTweetId != null) {
                          // 編集モード
                          final success =
                              await activityPostUseCase.updateActivity(
                            tweetId: editingTweetId!,
                            userId: user.id,
                            gymId: gymId!,
                            visitedDate: _selectedDate,
                            tweetContents: _textController.text,
                            mediaFiles: _mediaFiles,
                            existingUrls: _uploadedUrls,
                            originalUrls: originalUrls,
                          );

                          if (success) {
                            // 統計データのキャッシュを無効化して最新データを取得させる
                            ref.invalidate(statisticsProvider);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('編集が完了しました')),
                              );
                              Navigator.of(context).pop();
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('編集に失敗しました')),
                              );
                            }
                          }
                        } else {
                          // 新規投稿モード
                          final success =
                              await activityPostUseCase.postActivity(
                            userId: user.id,
                            gymId: gymId!,
                            visitedDate: _selectedDate,
                            tweetContents: _textController.text,
                            mediaFiles: _mediaFiles,
                          );

                          if (success) {
                            // 統計データのキャッシュを無効化して最新データを取得させる
                            // これにより「今月のボル活」ウィジェットが自動的に更新される
                            ref.invalidate(statisticsProvider);

                            // 投稿ページ初期化
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('投稿が完了しました')),
                              );

                              // ジム詳細ページから来た場合は前画面に戻る
                              if (widget.fromGymDetail) {
                                Navigator.of(context).pop();
                              } else {
                                // 通常の投稿タブから来た場合は初期化
                                setState(() {
                                  _selectedDate = DateTime.now();
                                  selectedGym = null;
                                  gymId = null;
                                  _textController.clear();
                                  _mediaFiles.clear();
                                  _uploadedUrls.clear();
                                });
                              }
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('投稿に失敗しました')),
                              );
                            }
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('エラーが発生しました: $e')),
                          );
                        }
                      }
                    }

                    // 投稿(編集)処理終了
                    setState(() => _isPosting = false);
                  },
            child: _isPosting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blue,
                    ),
                  )
                : Text(
                    isEditMode ? '更新する' : '投稿する',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ジム選択フィールド
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  hintText: selectedGym ?? "ジムを選択してください",
                  hintStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const GymSelectionPage(selectionMode: true)),
                  );

                  if (result != null && result is Map<String, dynamic>) {
                    setState(() {
                      selectedGym = result['gymName'];
                      gymId = result['gymId'];
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // 日付選択ボタン
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "ジム訪問日：${DateFormat('yyyy.MM.dd').format(_selectedDate)}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // テキスト入力フィールド
              TextField(
                controller: _textController,
                maxLength: 400,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: '今日登ったレベル，時間など好きなことを書きましょう。',
                  border: InputBorder.none,
                ),
              ),

              // カウンターと写真追加ボタン
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 写真一覧
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // 編集モード時：既存画像を表示
                        if (_uploadedUrls.isNotEmpty)
                          ..._uploadedUrls
                              .where((url) =>
                                  ImageUrlValidator.isValidImageUrl(url))
                              .map((url) {
                            final index = _uploadedUrls.indexOf(url);

                            return Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Image.network(
                                    url,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 100,
                                        height: 100,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.error,
                                            color: Colors.grey),
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _uploadedUrls.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),

                        // 新規画像を表示（✗ボタン付き）
                        ..._mediaFiles.asMap().entries.map((entry) {
                          final index = entry.key;
                          final file = entry.value;
                          return Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Image.file(
                                  file,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _mediaFiles.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 写真追加ボタン
                  GestureDetector(
                    onTap: () {
                      _pickMultipleImages();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.image, size: 30, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            '写真を追加',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 写真枚数カウンター
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      '${_uploadedUrls.length + _mediaFiles.length} / 5枚',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
