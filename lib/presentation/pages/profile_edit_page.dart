import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../domain/entities/user.dart';
import '../../domain/entities/gym.dart';
import '../providers/user_provider.dart';
import '../providers/gym_provider.dart';
import '../providers/dependency_injection.dart';
import '../components/common/loading_widget.dart';
import '../components/common/error_widget.dart';
import '../../shared/utils/navigation_helper.dart';
import 'gym_selection_page.dart';

/// プロフィール編集ページ
///
/// 役割:
/// - ユーザープロフィール情報の編集
/// - プロフィール画像の変更
/// - ホームジムの設定
/// - 自己紹介文の編集
class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _introductionController = TextEditingController();
  final TextEditingController _gymSearchController = TextEditingController();
  final TextEditingController _favoriteGymsController = TextEditingController();

  File? _selectedProfileImage;
  Gym? _selectedHomeGym;
  DateTime? _selectedBirthday;
  DateTime? _selectedBoulStartDate;
  int? _selectedGender;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentUserData();
      ref.read(gymListProvider.notifier).loadAllGyms();
    });
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _introductionController.dispose();
    _gymSearchController.dispose();
    _favoriteGymsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final gymListState = ref.watch(gymListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール編集'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _hasChanges && !_isSaving ? _saveProfile : null,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: userState.when(
        data: (user) => _buildEditForm(user, gymListState),
        loading: () => const Center(
          child: LoadingWidget(message: 'プロフィール情報を読み込み中...'),
        ),
        error: (error, stackTrace) => Center(
          child: AppErrorWidget(
            message: 'プロフィール情報の取得に失敗しました',
            onRetry: () => _loadCurrentUserData(),
          ),
        ),
      ),
    );
  }

  Widget _buildEditForm(User? user, AsyncValue<List<Gym>> gymListState) {
    if (user == null) {
      return const Center(child: Text('ユーザー情報が見つかりません'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileImageSection(user),
          const SizedBox(height: 24),
          _buildUserNameSection(),
          const SizedBox(height: 24),
          _buildIntroductionSection(),
          const SizedBox(height: 24),
          _buildHomeGymSection(gymListState),
          const SizedBox(height: 24),
          _buildFavoriteGymSection(),
          const SizedBox(height: 24),
          _buildBirthdaySection(user),
          const SizedBox(height: 24),
          _buildGenderSection(user),
          const SizedBox(height: 24),
          _buildBoulStartDateSection(user),
          const SizedBox(height: 24),
          _buildAccountInfoSection(user),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'プロフィール画像',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: _selectedProfileImage != null
                    ? FileImage(_selectedProfileImage!)
                    : (user.userIconUrl != null && user.userIconUrl!.isNotEmpty)
                        ? NetworkImage(user.userIconUrl!)
                        : null,
                child: _selectedProfileImage == null &&
                        (user.userIconUrl == null || user.userIconUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 60)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: IconButton(
                    onPressed: _pickProfileImage,
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    iconSize: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ユーザー名',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _userNameController,
          decoration: const InputDecoration(
            hintText: 'ユーザー名を入力',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(16),
          ),
          maxLength: 30,
          onChanged: (value) => _onFieldChanged(),
        ),
      ],
    );
  }

  Widget _buildIntroductionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '自己紹介',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _introductionController,
          decoration: const InputDecoration(
            hintText: '自己紹介を入力してください\n好きな課題の種類、目標グレード、ボルダリング歴など',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(16),
          ),
          maxLines: 4,
          maxLength: 200,
          onChanged: (value) => _onFieldChanged(),
        ),
      ],
    );
  }

  Widget _buildHomeGymSection(AsyncValue<List<Gym>> gymListState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ホームジム',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        if (_selectedHomeGym != null)
          _buildSelectedHomeGymCard()
        else
          _buildHomeGymSearchField(gymListState),
      ],
    );
  }

  Widget _buildSelectedHomeGymCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _selectedHomeGym!.photoUrls.isNotEmpty
                  ? Image.network(
                      _selectedHomeGym!.photoUrls.first,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.fitness_center),
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.fitness_center),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedHomeGym!.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedHomeGym!.fullAddress,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() => _selectedHomeGym = null);
                _onFieldChanged();
              },
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeGymSearchField(AsyncValue<List<Gym>> gymListState) {
    return GestureDetector(
      onTap: _selectHomeGym,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: Colors.grey),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'ホームジムを選択してください',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  /// ホームジム選択ページへの遷移
  Future<void> _selectHomeGym() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const GymSelectionPage(selectionMode: true),
      ),
    );

    if (result != null &&
        result['gymId'] != null &&
        result['gymName'] != null) {
      // 選択されたジム情報を基にGymオブジェクトを作成（表示用の最小構成）
      final selectedGym = Gym(
        id: result['gymId'] as int,
        name: result['gymName'] as String,
        hpLink: '',
        prefecture: '',
        city: '',
        addressLine: '',
        latitude: 0,
        longitude: 0,
        telNo: '',
        fee: '',
        minimumFee: 0,
        equipmentRentalFee: '',
        ikitaiCount: 0,
        boulCount: 0,
        isBoulderingGym: true,
        isLeadGym: false,
        isSpeedGym: false,
        hours: const GymHours(), // 空のGymHoursオブジェクト
        photoUrls: const [],
      );

      setState(() {
        _selectedHomeGym = selectedGym;
        _gymSearchController.clear();
      });
      _onFieldChanged();
    }
  }

  Widget _buildFavoriteGymSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'お気に入りのジム',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _favoriteGymsController,
          decoration: const InputDecoration(
            hintText: 'お気に入りのジムを紹介してください\n例: クライミングジム・ロックス\nこのジムは初心者にも優しいです',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(16),
          ),
          maxLines: 4,
          maxLength: 200,
          onChanged: (value) => _onFieldChanged(),
        ),
      ],
    );
  }

  Widget _buildAccountInfoSection(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'アカウント情報',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('メールアドレス', user.email),
                const Divider(),
                _buildInfoRow('ユーザーID', _maskUserId(user.id)),
                const Divider(),
                _buildInfoRow(
                    '登録日',
                    user.boulStartDate != null
                        ? '${user.boulStartDate!.year}年${user.boulStartDate!.month}月${user.boulStartDate!.day}日'
                        : '未設定'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildBirthdaySection(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '生年月日(非公開)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            // TODO: 日付選択ダイアログを実装
            _showDatePicker('birthday');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    (_selectedBirthday ?? user.birthday) != null
                        ? "${(_selectedBirthday ?? user.birthday)!.year}年${(_selectedBirthday ?? user.birthday)!.month}月${(_selectedBirthday ?? user.birthday)!.day}日"
                        : "未設定",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSection(User user) {
    // ユーザーが新しい性別を選択した場合はその値を、そうでなければ元の値を表示
    final int currentGender = _selectedGender ?? user.gender ?? 0;
    String genderText;
    switch (currentGender) {
      case 0:
        genderText = '未回答';
        break;
      case 1:
        genderText = '男性';
        break;
      case 2:
        genderText = '女性';
        break;
      default:
        genderText = '未回答';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '性別(非公開)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            // TODO: 性別選択ダイアログを実装
            _showGenderSelectionDialog();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    genderText,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBoulStartDateSection(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ボルダリング開始日',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            // TODO: 日付選択ダイアログを実装
            _showDatePicker('boulStartDate');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.fitness_center, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    // ユーザーが新しい日付を選択した場合はその値を、そうでなければ元の値を表示
                    (_selectedBoulStartDate ?? user.boulStartDate) != null
                        ? "${(_selectedBoulStartDate ?? user.boulStartDate)!.year}年${(_selectedBoulStartDate ?? user.boulStartDate)!.month}月${(_selectedBoulStartDate ?? user.boulStartDate)!.day}日"
                        : "未設定",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _loadCurrentUserData() {
    final userState = ref.read(userProvider);
    userState.whenData((user) {
      if (user != null) {
        setState(() {
          _userNameController.text = user.userName;
          _introductionController.text = user.userIntroduce ?? '';
          _favoriteGymsController.text = user.favoriteGym ?? '';
          _selectedBirthday = user.birthday;
          _selectedBoulStartDate = user.boulStartDate;
          _selectedGender = user.gender;
        });

        // ホームジムの情報を取得（ID 0は選択なしとして扱う）
        if (user.homeGymId != null && user.homeGymId! > 0) {
          _loadHomeGym(user.homeGymId!);
        }
      }
    });
  }

  Future<void> _loadHomeGym(int gymId) async {
    try {
      await ref.read(gymDetailProvider.notifier).loadGymDetail(gymId);
      final gymState = ref.read(gymDetailProvider);
      gymState.whenData((gym) {
        if (gym != null) {
          setState(() => _selectedHomeGym = gym);
        }
      });
    } catch (e) {
      // エラーは無視
    }
  }

  void _onFieldChanged() {
    setState(() => _hasChanges = true);
  }

  Future<void> _showDatePicker(String type) async {
    final now = DateTime.now();
    final user = ref.read(userProvider).value;

    DateTime initialDate;
    DateTime firstDate;
    DateTime lastDate;

    if (type == 'birthday') {
      // 現在選択されている誕生日を優先的に使用（選択済みなら_selectedBirthday、そうでなければDBの値）
      initialDate = _selectedBirthday ?? user?.birthday ?? DateTime(2000, 1, 1);
      firstDate = DateTime(1900);
      lastDate = now;
    } else {
      // boulStartDate
      // 現在選択されているボルダリング開始日を優先的に使用（選択済みなら_selectedBoulStartDate、そうでなければDBの値）
      initialDate = _selectedBoulStartDate ?? user?.boulStartDate ?? now;
      firstDate = DateTime(1990);
      lastDate = now;
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (selectedDate != null) {
      setState(() {
        _hasChanges = true;
        if (type == 'birthday') {
          _selectedBirthday = selectedDate;
        } else {
          _selectedBoulStartDate = selectedDate;
        }
      });
    }
  }

  Future<void> _showGenderSelectionDialog() async {
    final user = ref.read(userProvider).value;
    if (user == null) return;

    // 現在選択されている値を優先的に使用（選択済みなら_selectedGender、そうでなければDBの値）
    final currentGender = _selectedGender ?? user.gender ?? 0;

    final selectedGender = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('性別を選択'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('未回答'),
              leading: Radio<int>(
                value: 0,
                groupValue: currentGender, // 現在選択中の値を反映
                onChanged: (value) => Navigator.pop(context, value),
              ),
            ),
            ListTile(
              title: const Text('男性'),
              leading: Radio<int>(
                value: 1,
                groupValue: currentGender, // 現在選択中の値を反映
                onChanged: (value) => Navigator.pop(context, value),
              ),
            ),
            ListTile(
              title: const Text('女性'),
              leading: Radio<int>(
                value: 2,
                groupValue: currentGender, // 現在選択中の値を反映
                onChanged: (value) => Navigator.pop(context, value),
              ),
            ),
          ],
        ),
      ),
    );

    if (selectedGender != null && selectedGender != currentGender) {
      setState(() {
        _hasChanges = true;
        _selectedGender = selectedGender;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      // 画像選択UseCase取得
      final selectProfileImageUseCase =
          ref.read(selectProfileImageUseCaseProvider);

      final selectedImage = await selectProfileImageUseCase.execute();

      if (selectedImage != null) {
        setState(() {
          _selectedProfileImage = selectedImage;
        });
        _onFieldChanged();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像選択に失敗しました: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_hasChanges || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      // ユーザー名の必須チェック
      if (_userNameController.text.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ユーザー名の入力は必須です'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // プロフィール情報の更新処理
      // ホームジムIDを準備（未選択の場合は0を送信）
      final homeGymIdToSend = _selectedHomeGym?.id ?? 0;

      // 各入力フィールドから値を取得し、空文字の場合はデフォルト値を設定
      final userNameValue = _userNameController.text.trim();
      final userIntroduceValue = _introductionController.text.trim().isEmpty
          ? "-"  // 空の場合はクリア指示として"-"を送信
          : _introductionController.text.trim();
      final favoriteGymValue = _favoriteGymsController.text.trim().isEmpty
          ? "-"  // 空の場合はクリア指示として"-"を送信
          : _favoriteGymsController.text.trim();

      // UserProviderを通じて一括でプロフィール情報を更新
      await ref.read(userProvider.notifier).updateProfile(
            userName: userNameValue,
            userIntroduce: userIntroduceValue,
            favoriteGym: favoriteGymValue,
            homeGymId: homeGymIdToSend,
            gender: _selectedGender,
            birthday: _selectedBirthday,
            boulStartDate: _selectedBoulStartDate,
          );

      // プロフィール画像の更新処理（新しい画像が選択されている場合のみ実行）
      if (_selectedProfileImage != null) {
        // アイコン更新用UseCaseを取得
        final updateUserIconUseCase = ref.read(updateUserIconUseCaseProvider);
        
        // 現在ログイン中のユーザー情報を取得
        final currentUser = ref.read(userProvider).value;
        
        if (currentUser != null) {
          try {
            // 画像ファイルをクラウドストレージにアップロードし、DBのアイコンURLを更新
            await updateUserIconUseCase.execute(
                currentUser.id, _selectedProfileImage!.path);
          } catch (e) {
            // アイコン更新でエラーが発生した場合は上位で処理
            rethrow;
          }
        }
      }

      // プロフィール更新完了後、最新のユーザー情報を再取得
      await ref.read(userProvider.notifier).refreshUser();

      if (mounted) {
        // UI状態を更新：変更フラグをリセット
        setState(() => _hasChanges = false);

        // 編集画面を閉じて前の画面に戻る
        Navigator.of(context).pop();
        
        // 更新成功をユーザーに通知
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('プロフィールを更新しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        NavigationHelper.showErrorDialog(
          context: context,
          message: 'プロフィールの更新に失敗しました: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// ユーザーIDを部分表示する関数
  /// 最初の8文字のみを表示し、残りはアスタリスクで隠す
  ///
  /// [id] 表示するユーザーID
  /// 返り値: 部分表示されたユーザーID（例: "uX1TC0Dl************"）
  String _maskUserId(String id) {
    const visibleLength = 8;

    if (id.length <= visibleLength) {
      return id;
    }

    final visiblePart = id.substring(0, visibleLength);
    final maskedLength = id.length - visibleLength;
    final maskedPart = '*' * maskedLength;

    return '$visiblePart$maskedPart';
  }
}
