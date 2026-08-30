# 深掘り: Riverpod プロバイダの読み方（autoDispose / family / create関数）

トピック03（Riverpod入門）の応用編。本体アプリ「イワノボリタイ」の**実際のツイート系プロバイダ**を教材に、
`autoDispose`・`family`・プロバイダ定義のコールバック（create関数）を分解して読めるようになるためのノート。

対象の実コード（本体側）:
- `lib/presentation/providers/general_tweets_provider.dart`（`generalTweetsProvider`）
- `lib/presentation/providers/favorite_user_tweets_provider.dart`（`favoriteUserTweetsProvider`）

---

## 1. プロバイダ定義の全体構造

プロバイダの定義は、結局のところ**ただの変数定義**：

```dart
final 変数名 = StateNotifierProvider<型パラメータ...>( 引数 );
```

- `変数名` … これを `ref.watch(変数名)` で使う。
- `StateNotifierProvider<...>(...)` … これが返すオブジェクト（プロバイダ）を変数に代入しているだけ。
- `( 引数 )` の中身が **「Notifierを作る関数（create関数）」**。ここが最重要。

---

## 2. 型パラメータの読み方（2つ vs 3つ）

先頭からの意味は固定。`family` かどうかで3番目が増えるだけ。

| 位置 | 意味 | 引数なし（2つ） | family（3つ） |
|---|---|:---:|:---:|
| 1番目 | **Notifier**（状態を操作する本体クラス） | ✅ | ✅ |
| 2番目 | **State**（保持する状態の型） | ✅ | ✅ |
| 3番目 | **引数（family パラメータ）の型** | — | ✅ |

→ 「前2つは常に Notifier, State。familyは3番目に"引数の型"を足すだけ」。

---

## 3. create関数（コールバック）の意味

`StateNotifierProvider(...)` に渡している `(...)` は、**Notifierを生成する関数**。
Riverpodが「必要になったら呼ぶ」ために手渡す。自分では呼ばない。

### 引数なしの例: generalTweetsProvider（「みんなのボル活」は全体で1つ）

```dart
final generalTweetsProvider = StateNotifierProvider<
    GeneralTweetsNotifier,   // ① Notifier
    GeneralTweetsState        // ② State
>((ref) {                     // ← 引数なし → コールバックは (ref) だけ
  final getTweetsUseCase = ref.read(getTweetsUseCaseProvider);  // 部品を調達（DI）
  return GeneralTweetsNotifier(getTweetsUseCase);               // 本体を生成して返す
});
```

使う側:
```dart
final state = ref.watch(generalTweetsProvider);   // 引数を渡さない
```

### family の例: favoriteUserTweetsProvider（「誰の」お気に入りかで変わる）

```dart
final favoriteUserTweetsProvider = StateNotifierProvider.family<
    FavoriteUserTweetsNotifier,   // ① Notifier
    FavoriteUserTweetsState,      // ② State
    String                        // ③ 引数の型（userId が String）
>((ref, userId) {                 // ← family なので (ref, userId) の2引数
  final getFavoriteTweetsUseCase = ref.read(getFavoriteTweetsUseCaseProvider);
  return FavoriteUserTweetsNotifier(userId, getFavoriteTweetsUseCase);
});
```

使う側:
```dart
final state = ref.watch(favoriteUserTweetsProvider(userId));   // userId を渡す
```

### コールバックの2つの引数
- **`ref`** … 他のプロバイダにアクセスする窓口。`ref.read(別のProvider)` で部品を取り寄せる（依存性注入）。
- **`userId`**（familyのみ）… 呼び出し側 `favoriteUserTweetsProvider("user_A")` の `"user_A"` がここに届く。

### 中身の2行がやること
1. `ref.read(...)` で必要な UseCase（部品）を取得。
2. `return Notifier(...)` で **Notifier本体を生成して返す**。返したNotifierがこのプロバイダの中身になる。

---

## 4. 誰が・いつ create関数を呼ぶか（トレース）

自分では呼ばない。**Riverpodが、必要になった瞬間に、遅延で呼ぶ**。

```
UI: ref.watch(favoriteUserTweetsProvider("user_A"))
  └ Riverpod: "user_A" のNotifierは既にある？
       ├─ 無い → create関数を (ref, "user_A") で呼ぶ
       │         → ref.read でUseCase取得
       │         → FavoriteUserTweetsNotifier("user_A", useCase) を生成
       │         → Notifierのコンストラクタが DB取得(_fetchMore...) を実行
       │         → 生成したNotifierを "user_A" のキーで保管
       └─ 有る → 保管済みNotifierの状態をそのまま返す（create関数は呼ばれない＝再取得しない）
```

`family` は「引数の値ごとに別インスタンス」。`("user_A")` と `("user_B")` は**別々のNotifier・別々のState**として保管される。

---

## 5. autoDispose（寿命）と、本体で行った修正

`autoDispose` は**プロバイダの寿命の修飾子**。`family` とは独立した別スイッチ。

| | autoDisposeなし | autoDisposeあり |
|---|---|---|
| 挙動 | 一度作ったらアプリ生存中ずっと保持（使い回す） | 誰も見なくなった瞬間に破棄。次に見たら作り直す |
| create関数 | 初回だけ呼ばれる | 見られるたびに呼ばれ得る |

本体のツイート系Notifierは**コンストラクタでDB取得する**ため、
autoDisposeありだと「タブを離れる→破棄→戻る→create関数再実行→再取得」となっていた。

### 2026-08-30 の修正（PR #27）
「画面を開くたびの再取得」を止めるため、次の2つから `.autoDispose` を除去し、状態を永続化した：
- `generalTweetsProvider`: `StateNotifierProvider.autoDispose<N,S>` → `StateNotifierProvider<N,S>`
- `favoriteUserTweetsProvider`: `StateNotifierProvider.family.autoDispose<N,S,String>` → `StateNotifierProvider.family<N,S,String>`
  - **family は残す**（userIdごとに分けるのは必要）／autoDisposeだけ外す。

結果: DBアクセスは「アプリ起動後の初回取得」と「Pull-refresh」のときだけになった。
（マイページの `myTweetsProvider` は元々 autoDispose 無しで、既にこの挙動だった。）

### 修飾子の4通り（組み合わせ）
| 書き方 | family | autoDispose |
|---|:---:|:---:|
| `StateNotifierProvider<N,S>` | ✗ | ✗ |
| `StateNotifierProvider.autoDispose<N,S>` | ✗ | ✓ |
| `StateNotifierProvider.family<N,S,Arg>` | ✓ | ✗ |
| `StateNotifierProvider.family.autoDispose<N,S,Arg>` | ✓ | ✓ |

---

## 関連
- 動く最小デモ: 同フォルダ `riverpod_basics_page.dart`（(1)〜(6)の Provider 種別）
- 上位トピック: `README.md`（Riverpod入門）
