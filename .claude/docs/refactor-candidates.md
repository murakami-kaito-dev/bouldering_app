# リファクタ候補メモ（refactor-candidates）

2026-08-21 全ファイル調査で発見した「冗長・不要・未使用・要修正」箇所の記録。
**ルール: 削除・修正は一切しない。ユーザー許可が出るまで記録のみ。**
コメントアウトで意図的に残されたロジック（Mock切替用、TODO明記、`削除しない`注記付き等）は除外済み。
確度: **高** = 参照ゼロ等を機械的に確認済み / **要判断** = 意図的な可能性がありユーザー判断が必要。

---

## 0. バグ（リファクタではなく修正が必要なもの・優先度最高）

| # | 場所 | 内容 | 確度 |
|---|---|---|---|
| B-1 | `backend/src/infrastructure/repositories/PostgresTweetRepository.ts:443-450` | tweet_mediaのDELETEに`RETURNING`がなく結果が常に空 → **メディア削除が成功しても必ず404を返す**（フロント未使用のため実害は未発現） | 高（バグ確定） |
| B-2 | `backend/src/routes/gyms.ts` | `GET /:gym_id` が先に定義されているため `GET /ikitai-counts` / `GET /boul-counts` に**到達不能**（フロント未使用で実害なし。修正か削除かの判断要） | 高 |
| B-3 | `backend/src/routes/reports.ts:19` | `POST /api/reports` に `authenticate` がなく、`reporter_user_id` をボディで受ける → **なりすまし通報可能** | 高（セキュリティ） |
| B-4 | `backend/src/routes/internal_tasks.ts:44-72` | `verifyCloudTasksAuth` がOIDC検証未実装（TODOのまま）→ **外部から任意ユーザーのGCSメディア一括削除可能** | 高（セキュリティ） |
| B-5 | `backend/.dockerignore` | `.env.dev`/`.env.prod`/`dist` が除外されておらず**DBパスワード入りenvがDockerイメージに焼き込まれる** | 高（セキュリティ） |
| B-6 | `lib/shared/config/environment_config.dart:124,136` | **DBパスワード平文ハードコード（Git追跡下）**。当該`databaseConfig`は未使用なので削除で解決するが、Git履歴に残るためローテーション要否は要判断 | 高（セキュリティ） |
| B-7 | `pubspec.yaml:69-70` + `lib/infrastructure/services/storage_service.dart:232` | GCSサービスアカウント鍵をアセット同梱（バイナリから抽出可能）。署名付きURL方式への移行は設計変更を伴う | 要判断（セキュリティ） |
| B-8 | `lib/infrastructure/datasources/gym_datasource.dart:326-329` | ハーバーサイン距離計算が数学的に誤り（`sin`不使用）→ 半径フィルタが仕様通り効かない | 高（バグ） |
| B-9 | `lib/infrastructure/datasources/tweet_datasource.dart:92-95` | `offset`をAPIに渡さない空if → `getTweetsByUserId`のページネーション不動作の可能性 | 高 |
| B-10 | `lib/presentation/pages/gym_search_page.dart:31-36` | build内で`addPostFrameCallback`→state2回更新 → **無限リビルドループ**の構造 | 高 |
| B-11 | `lib/presentation/pages/gym_map_page.dart:59` | 存在しない `assets/images/gym_pin.png` を参照（実在は `assets/pin_48.png`）→ 常にデフォルトマーカー | 高 |
| B-12 | `lib/presentation/pages/settings_page.dart:314` | バージョン表記「1.0.0」ハードコード（実際は1.0.1+2）。package_info_plus等で動的取得すべき | 高 |
| B-13 | `lib/infrastructure/services/api_client.dart:103-131` | 例外の二重ラップでstatusCodeが失われ、上位で401判別不能 | 高 |
| B-14 | フロント（likes系呼び出し） | フロントが `/tweets/{id}/likes` を呼ぶがバックエンドに**ルートが存在しない**（いいね機能は未配線。フロント側削除かバックエンド実装かの判断要） | 要判断 |
| B-15 | `backend/src/routes/internal_tasks.ts:24` / `storageService.ts:17` | `GCS_BUCKET_NAME`未設定時のフォールバックがdevバケット名 → prodで設定漏れするとdevバケットを操作 | 高 |
| B-16 | `backend/src/services/storageCleanupPublisher.ts:481-495` | 必須env欠落時に画像削除が`console.warn`だけで**サイレント無効化**（画像孤児化に気づけない） | 中 |
| B-17 | `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner Prod.xcscheme` | BuildableNameが`Bouldering App Dev.app`（Prodなのに）。両スキームのProfile/AnalyzeActionが存在しない構成`Release-dev`/`Debug-dev`を参照 | 高 |
| B-18 | `lib/presentation/components/tweet/favorite_tweets_section.dart:211` | エラー時に永久スピナー（`error: (_,__) => CircularProgressIndicator()`） | 高 |
| B-19 | `lib/presentation/components/user/other_user_tweets_section.dart:44` | スクロール判定が厳密等値`==`（他は`>= -100`）でページング発火しにくい | 高 |
| B-20 | `lib/presentation/components/user/other_user_profile_section.dart:193-204` | homeGymId=0の扱いが他画面と不統一（0でも青リンク+無効遷移） | 高 |

## 1. フロントエンド: 未使用ファイル（丸ごと削除候補）

| 場所 | 理由 | 確度 |
|---|---|---|
| `lib/shared/data/mock_data.dart` + `lib/infrastructure/services/mock_api_client.dart` + `mock_auth_service.dart` + `mock_storage_service.dart` + `lib/infrastructure/datasources/mock_user_datasource.dart`（計1,415行） | 参照はコメントアウト行のみ。テストも存在しない（ただしMock切替コメント自体は意図的に温存されている → セットで要判断） | 高 |
| `lib/domain/repositories/activity_repository.dart`（140行）+ `lib/domain/entities/activity_post.dart`（174行） | 実装クラス・DI登録なし。実際のActivityPostUseCaseはTweetRepository/StorageRepositoryを使用 | 高 |
| `lib/domain/entities/favorite_relation.dart`（69行） | 参照ゼロ | 高 |
| `lib/presentation/providers/favorite_gym_provider.dart`（208行） | 全Provider参照ゼロ（イキタイ登録はgym_detail_pageがUseCaseを直接使用）。※gym_detail_pageの自前状態管理との統合も要検討 | 高 |
| `lib/presentation/providers/tweet_post_provider.dart`（225行） | 全Provider参照ゼロ（投稿はactivityPostUseCaseProvider経由） | 高 |
| `lib/presentation/components/user/user_card.dart`（265行） | 参照ゼロ + `_toggleFollow`本体コメントアウト | 高 |
| `lib/presentation/components/setting/setting_item.dart`（64行） | 参照ゼロ（settings_pageは独自実装） | 高 |
| `scripts/force_logout.dart` | `lib/main_force_logout_*.dart`と重複、かつ`dart run`では動作不能（Firebase初期化がVM非対応） | 高 |
| `lib/view/assets/date_range.svg`, `home_gim_icon.svg` | 参照ゼロ（pubspec宣言のみ）。コード上はIcons.date_range/Icons.homeに置換済み | 高 |
| `assets/pin_48.png` | 参照ゼロ（B-11と関連: 本来のマーカー画像だった可能性） | 高 |
| `lib/main_force_logout_dev.dart` / `_prod.dart` の2本立て | ほぼ完全重複（差分はimportと文字列のみ）。統合可能だが運用ツールなので要判断 | 要判断 |

## 2. フロントエンド: 未使用クラス・メソッド・プロパティ（抜粋）

| 場所 | 内容 | 確度 |
|---|---|---|
| `lib/shared/config/environment_config.dart:87-192` | `gcsBucketName`/`databaseConfig`/`firebaseConfigPath`/`apiTimeoutSeconds`/`logLevel` 全て呼び出しゼロ。※apiTimeoutSecondsはApiClientに渡されず30秒固定になっている | 高 |
| `lib/shared/utils/navigation_helper.dart` | `toGymSearch`/`toGymMap`/`toTweetPost`/`toTweetDetail`/`toFavoriteUsers`/`toFavoriteGyms`/`toSettings`/`showSuccessDialog`/`showLoadingDialog`/`showBottomSheet`/`getRouteParam` 参照ゼロ（`toTweetDetail`等はルート未登録で呼べば例外） | 高 |
| `lib/shared/constants/app_routes.dart` | `loginOrSignup`/`gymNameSearch`/`tweetDetail`/`userProfile`/`favoriteGyms` 未登録・未使用 | 高 |
| `lib/shared/services/navigation_service.dart:42,60,66` | `navigateToGymSearch`（未登録ルート）/`pop`/`popUntil` 参照ゼロ | 高 |
| `lib/shared/utils/type_converter.dart` | `stringToIdOrThrow`/`toInt`/`toStringValue`/`InvalidIdFormatException` 未使用（idToStringのみ使用） | 高 |
| `lib/shared/utils/prefecture_order_utils.dart:84,106` / `prefecture_constants.dart:71,74` | `getGymsByPrefecture`/`prefectureOrder`/`regionNames`/`getRegionByPrefecture` 参照ゼロ | 高 |
| `lib/domain/entities/gym.dart:54-85` | `Gym.isCurrentlyOpen` 未使用（GymHoursUtilsと完全重複、後者を使用中） | 高 |
| `lib/domain/entities/tweet.dart` | `toJson`/`fromJson`/`hasMedia`/`hasMovie`/`timeAgoDisplay`/`timeSincePosted` 未使用 | 高 |
| `lib/domain/entities/bouldering_stats.dart:266,278` | `fromJson`/`mock` 未使用 | 高 |
| datasource→repo→IFの3層貫通で未使用: `getTweetById`/`likeTweet`/`unlikeTweet` | いいね機能は未配線（B-14と関連） | 要判断 |
| `TweetDataSource.uploadPostMedia`（`tweet_datasource.dart:408-418`） | 呼び出しゼロ。消せば`_storageService`依存ごと削減可 | 高 |
| `BlockUseCase.isMutuallyBlocked` 〜 `block_datasource.dart:65-68` | isBlockedの単純エイリアス、UI未使用 | 高 |
| `ActivityPostUseCase.validatePostContent`（`activity_post_usecases.dart:183-205`） | 呼び出しゼロ、ActivityPost.isValid()と重複 | 高 |
| `lib/presentation/providers/gym_provider.dart:19-53,100-181,220-222,254-276` | `GymSearchFilter`クラス、`searchGyms`/`loadPopularGyms`/`searchNearbyGyms`/`clearFilter`/`refresh`/`clearGymDetail`、`currentGymFilterProvider`等 未使用。連鎖して`getPopularGymsUseCaseProvider`/`getNearbyGymsUseCaseProvider`も実質デッド | 高 |
| `lib/presentation/providers/user_provider.dart:386,408` | `isLoggedInProvider`未使用。`authServiceProvider`(408行)は未使用かつ**dependency_injection.dart:69の同名Providerと衝突リスク** | 高 |
| providers各所の未使用派生Provider | `isMyTweetsLoadingProvider`/`myTweetsListProvider`/`isOtherUserTweetsLoadingProvider`/`otherUserTweetsListProvider`/`isInFavoriteUsersListProvider`/`isInFavoritedByUsersListProvider`/`blockProvider.clearError`/`reportProvider.reset`/`selectPostImagesUseCaseProvider` | 高 |
| `lib/presentation/components/common/error_widget.dart:58,77` / `loading_widget.dart:52` | `NetworkErrorWidget`/`EmptyDataWidget`/`InlineLoadingWidget` 参照ゼロ | 高 |
| `lib/infrastructure/repositories/gym_repository_impl.dart:192-231` | `incrementIkitaiCount`/`decrementIkitaiCount` 常にtrueを返すスタブ | 高 |
| `NGWordsData.getCategorizedWords`（`ng_words_data.dart:74-81`） | 参照ゼロだが「将来的な拡張用」コメントあり | 要判断 |
| `ImageUrlValidator.isValidUrl`/`isPlaceholderUrl` | 外部からは`isValidImageUrl`/`filterValidImageUrls`のみ使用（private化候補） | 高 |
| `ModerationResult.firstDetectedWord`（`moderation_result.dart:705`相当） | 参照ゼロ | 高 |

## 3. フロントエンド: 重複ロジック（統合候補）

| 対象 | 内容 | 確度 |
|---|---|---|
| 営業時間判定 | `Gym.isCurrentlyOpen`（gym.dart:54-85）と`GymHoursUtils.isCurrentlyOpen`（gym_hours_utils.dart:18-62）が同一アルゴリズム。前者は死んでいる | 高 |
| ナビゲーション3方式 | `NavigationHelper`(pushNamed) / `NavigationService`(MaterialPageRoute) / 直書きMaterialPageRoute が混在。ジム詳細遷移は2実装 | 高 |
| `favorite_users_page.dart` vs `favorited_by_users_page.dart`（各219行） | 構造完全一致（Provider名・文言差のみ）。プロバイダも同様（各155行、実装完全同一） | 高 |
| 画像バリデーション | `image_picker_usecases.dart:57-90`と`:151-184`がほぼ同一（サイズ上限のみ差） | 高 |
| お気に入りユーザー詳細取得 | `favorite_usecases.dart:100-131`と`:155-186`が同一構造 + forループ直列await（N+1、Future.wait化余地） | 高 |
| メール正規表現 | `user_usecases.dart:165` / `user_repository_impl.dart:366` / `login_or_signup_page.dart:31` / `password_reset_page.dart:24` / `settings_page.dart:484`（別パターン）の5箇所 | 高 |
| `_parseInt`/`_parseDouble` | `gym_datasource.dart:292,304`と`favorite_datasource.dart:280`で重複（TypeConverter.toIntが未使用のまま存在） | 高 |
| `_formatDate` | `user_datasource.dart:503`と`tweet_datasource.dart:473`が同一実装 | 高 |
| 都道府県リスト | `prefecture_constants.dart:13-57`と`prefecture_order_utils.dart:12-39`で47件を二重管理 | 高 |
| NGワードチェック経路 | UseCase経由と`ng_word_validator.dart`のProvider直読みの2経路（後者はshared→presentationの層違反も） | 高 |
| 投稿経路 | `PostTweetUseCase`（後方互換と明記）と`ActivityPostUseCase.postActivity`（正規）の2本 | 要判断 |
| バリデーション多重実装 | monthsAgo 0-12チェック、limit 1-100チェックがusecase/repository implの両方に散在 | 中 |
| 48px円形アバター | `block_list_page.dart:121-152`と`favorite_user_card.dart:113-142`が逐語的に同一 | 高 |
| `user_avatar.dart` vs `user_logo_and_name.dart` | ほぼ同一（UserAvatarは1箇所のみ使用） | 高 |
| 「写真なし」プレースホルダ | gym_list_card/favorite_gym_card/gym_map_page/gym_detail_pageの4-5箇所で個別実装 | 高 |
| `_SliverAppBarDelegate` | `logged_in_my_page.dart:104-128`と`other_user_profile_page.dart:88-109`に2実装 | 高 |
| ジムカテゴリタグ描画 | 4箇所で同じif×3を反復 | 中 |
| `gym_list_card.dart` vs `favorite_gym_card.dart` | 構成同一（写真上限とタップ挙動のみ差） | 中 |
| 未ログイン誘導UI | 3画面に類似ブロック（文言が微妙に異なり意図的の可能性） | 要判断 |
| shared→presentationの層違反 | `ng_word_validator.dart:3`と`navigation_service.dart:2`がpresentationをimport | 高 |

## 4. フロントエンド: 冗長・デッドコード（抜粋）

| 場所 | 内容 | 確度 |
|---|---|---|
| repositories実装の`try/catch(e){rethrow;}` **32箇所** | tweet(10)/favorite(7)/gym(5)/firebase_auth_service(5)/block_datasource(4)/user(1)。削除しても挙動不変 | 高 |
| `print()`のリリース混入 | `auth_provider.dart`12箇所、`user_datasource.dart`6箇所（他はdebugPrint） | 高 |
| `storage_service.dart:7` | 未使用import `package:crypto`（ハッシュ計算は未実装） | 高 |
| `user_datasource.dart:428-435` | `if (response is Map)`常時true → else到達不能 | 高 |
| `gym_datasource.dart:340-342` | math関数の無意味なラッパ`_cos`/`_sqrt`/`_atan2` | 高 |
| `favorite_datasource.dart:161,260` | 同一エンドポイントを叩く2API（getFavoriteGymIds/getFavoriteGyms）片方に統合可 | 高 |
| `ng_words_data.dart:58-70` | 大文字小文字バリアントの重複登録（判定側が両辺toLowerCaseするため無意味） | 高 |
| `gym_detail_page.dart:40,46,80-86,513` | どこにも接続されていない`_scrollController`一式 | 高 |
| `report_page.dart:39` | 未使用の`ref.watch(userProvider)`（無駄な再ビルド購読） | 高 |
| `profile_edit_page.dart:32,58,385` | 死んだ`_gymSearchController` / `:319`未使用引数による不要な依存伝播 | 高 |
| `statistics_provider.dart:25-33` | 全例外握り潰しで0値返却 → 両画面のerrorブランチ到達不能（意図的フォールバックの可能性） | 要判断 |
| `favorite_users_page.dart`/`favorited_by_users_page.dart`の`RouteAware`実装 | RouteObserver未登録のため`didPopNext`は永久に呼ばれない | 高 |
| `terms_agreement_page.dart:163-166` / `home_page.dart:178-180` | 空ブロック | 高 |
| `general_tweets_section.dart:65-72` / `favorite_tweets_section.dart:172-179` | 何も描画しない追加ローディング行でitemCount+1 | 高 |
| `gym_type_selector.dart:51-68` | タップ処理の2重登録 | 高 |
| `boul_log.dart:170` | 外側で検証済みのnullチェック再実施 | 高 |
| `user_provider.dart:139,355` | stackTrace捨てのthrow Exception | 高 |
| `activity_post_page.dart:48,115-137,493` | フィールド化不要な変数 / setState内の副作用 / indexOf線形探索 | 中 |
| deprecated API | `WillPopScope`(settings_page:398) / `setMapStyle`(gym_map_page:142) / `CardTheme`(app.dart:129) / `Key? key`旧形式(activity_post_page:28) | 中 |
| non-nullableへの`??` | `favorite_user_card.dart:70` / `favorite_gym_card.dart:166` | 高 |
| `copyWith`のerror上書き挙動不統一 | block_provider/gym_tweets_provider/other_user_favorite_gyms_provider（常時上書き）vs my_tweets_provider（`?? this.error`） | 要判断 |
| `dependency_injection.dart:87-96` | FLAVOR/FLUTTER_APP_FLAVORを読んでdebugPrintするだけ（分岐はENVIRONMENTのみ） | 高 |
| `pubspec.yaml:41-51` | `assets/`丸ごと指定で`for_readme/`の図720KBがアプリに同梱 | 高 |
| pubspec未使用依存 | `cloud_functions`/`permission_handler`/`sqflite`/`path_provider`/`dartz`/`auto_route`(+generator)/`go_router`/`flutter_dotenv`/`flutter_cache_manager` いずれもlib内import 0件 | 高 |
| `gym_detail_page.dart:277` | 定休日が常に「なし」固定（営業時間データと未連動） | 要判断 |
| `gym_detail_page.dart:41,55-77` | イキタイ状態を自前setState管理（他画面と非同期） | 要判断 |
| `boul_log.dart:177-183` | 削除成功後のリスト再取得なし（コメントで自認） | 要判断 |

## 5. バックエンド

| 場所 | 内容 | 確度 |
|---|---|---|
| `backend/docker`（シンボリックリンク） | `/Applications/Docker.app/...`を指すローカル依存リンクが**Git追跡下**。他マシンでは壊れる。誤コミット | 高 |
| `backend/src/services/storageService.ts`（96行）+ `domain/services/IStorageService.ts` | import 0件。同等ロジックが`internal_tasks.ts:107-183`にインライン重複 → 削除か逆に統合か | 高 |
| `storageCleanupPublisher.ts:243-249,407-445` | `enqueueDeleteMediaUrl`/`enqueueMediaDeletion`/`derivePrefixFromUrl` 呼び出しゼロ（使用は`enqueueDeletePrefixes`のみ） | 高 |
| `config/database-cloudsql.ts` + 関連分岐 | Supabase移行後のロールバック用として意図的残置。Cloud SQLインスタンス完全廃止後に削除可 | 要判断 |
| `config/firebase.ts:11-24` | if(isProduction)の両分岐が完全同一コード | 高 |
| `routes/users.ts` | 本人確認403チェックが**13回コピペ**（requireSelfミドルウェア化候補）。688行の大半が定型 | 高 |
| URL→storage prefix導出が4実装 | PostgresTweetRepository内に2つ（:460,:551）+ publisher + StoragePathService（統合先として用意済み・`削除しない`注記あり） | 高 |
| `nodemon.json`の`tsconfig-paths/register` | `tsconfig-paths`が依存に存在せず、paths設定もない（脆い構成） | 高 |
| `jest.config.js` | tests/ディレクトリ不在・テスト0件。supertest等devDeps含め整理対象 | 高 |
| `models/types.ts` | `ClimbingType`/`GymHours`/`ApiResponse`/`PaginationParams`/`PaginatedResponse` 未使用。Gym内の40行コメントアウトプロパティは「将来実装予定」明記 → 後者は要判断 | 高/要判断 |
| `blockService.checkMutualBlockStatus`/`getBlockedUserIds` | ルートから未使用（フィルタはSQLサブクエリで実施） | 要判断 |
| `favoriteService.getGymFavoriteBy` 3層貫通 | 公開ルートが存在しない | 高 |
| `UserService`/`GymService`/`FavoriteService`のeventBusコンストラクタ注入 | 一度も未使用（publishするのはTweetServiceのみ） | 高 |
| `config/database.ts:103` `export {pool}` | 直接import箇所ゼロ（抽象化リーク） | 高 |
| `config/database.ts:59-75` `transaction()` | 呼び出しゼロ（TweetRepositoryは手書きBEGIN/COMMIT） | 高 |
| `routes/internal_tasks.ts:200-213` `GET /stats` | not implementedスタブ（バケット名・NODE_ENVを露出する副作用付き） | 高 |
| `utils/validation.ts:13` `validateGymId` | 未使用 | 高 |
| 未使用import散見（blocks.ts/reports.ts等） | tsconfigの`noUnusedLocals:false`で検出されない | 中 |
| 起動順序 | routes importのトップレベル`getXxxService()`により`validateEnvironment()`が実質後追い（B-16系の遠因） | 中 |
| `PostgresFavoriteRepository.ts:629,743` | RETURNINGなしDELETEのlength判定（冪等扱いで結果的に正しく動くが、ログが常に誤解を招く） | 中 |

## 6. 設定・その他

| 場所 | 内容 | 確度 |
|---|---|---|
| `firebase.json` | dev出力先`lib/firebase_options.dart`が実在しない（flutterfire configure再実行時に事故る） | 高 |
| `Runner.xcscheme`（旧デフォルト） | 削除済み構成Debug/Release/Profileを参照する死んだスキーム | 高 |
| `.vscode/` | C/C++ Runner拡張の設定のみ（Flutter用launch構成なし、絶対パスハードコード）。実質残骸 | 高 |
| `.idea/runConfigurations/main_dart.xml` | 存在しない`lib/main.dart`を起動する構成 | 高 |
| `docs/README.md` | リンクが旧ディレクトリ名で全切れ | 高 |
| `lib/README.md` | 2025年7月時点の内容で実装と乖離（`lib_new/`表記等）。ルートREADME/docs_publicと役割重複 | 要判断 |
| ルート`README.md`のAndroidビルドコマンド | flavor未定義のため動かない | 高 |
| `docs_public/setup/google_cloud_setup_private.txt` | 公開版なのに「private」名（中身はサニタイズ済みで安全） | 中 |
| マージ済み残存ブランチ | ローカル: feature/ng-word-filtering, feature/user-block, fix/photo-viewer-close, docs/add-implementation-doc / リモート: fix/keyboard-dismiss | 高 |
| `components/`直下3ファイル | favorite_gyms_section/my_tweets_section/this_month_boul_logだけカテゴリフォルダ外（配置不統一） | 中 |
| `presentation/components/common/boul_log.dart` | 427行の大型コンポーネント（表示+編集+削除+ブロック+報告が1ファイル） | 中 |
