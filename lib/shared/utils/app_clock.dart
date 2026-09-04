/// 時刻の基準（JST 固定）の共通部品
///
/// 方針（2026-09-05 決定）:
/// - このサービスは日本のジム・日本のユーザー向けなので、「今日」「今月」「営業中か」の判断は
///   端末のタイムゾーンに関係なく **日本時間（JST, UTC+9・夏時間なし）** で行う
/// - サーバー／DB は UTC 保存。日付だけの値（訪問日・生年月日・開始日）は 'YYYY-MM-DD' で
///   受け渡しし、時刻を付けない（時刻付きにすると 9 時間ずれて日付が変わる原因になる）
/// - 投稿時刻（tweeted_date）のような「瞬間」は従来どおり端末ローカルで表示してよい
///   （瞬間は世界共通で、表示だけ端末に合わせるのが正しい）
///
/// 使い分け:
/// - [nowJst] … 日本時間の現在の壁時計（曜日・時分の判定用）
/// - [todayJst] … 日本時間の今日（日付だけ）。未来判定・日付ピッカーの上限に使う
/// - [parseDateOnly] / [formatDateOnly] … DATE 列の読み書き
class AppClock {
  AppClock._();

  static const Duration jstOffset = Duration(hours: 9);

  /// テスト用に「現在」を差し替える（null なら実時刻）
  static DateTime Function()? debugNow;

  static DateTime _instant() => debugNow?.call() ?? DateTime.now();

  /// 日本時間の現在の壁時計。
  /// 返り値は isUtc=true の DateTime だが、year/month/day/hour/minute/weekday は日本時間の値
  /// （端末のタイムゾーンに依らない）。他の DateTime と直接比較せず、値の読み取りに使う
  static DateTime nowJst() => _instant().toUtc().add(jstOffset);

  /// 日本時間の今日（時刻なし・ローカル DateTime として組み立てる）
  static DateTime todayJst() {
    final j = nowJst();
    return DateTime(j.year, j.month, j.day);
  }

  /// 日付だけにそろえる（時刻を落とす）
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// 'YYYY-MM-DD' または 'YYYY-MM-DDTHH:mm:ss…' から日付だけを読む
  ///
  /// サーバーが DATE 列を "2026-09-05T00:00:00.000Z" のように時刻付きで返しても、
  /// 先頭の年月日だけを使うので端末のタイムゾーンで日付がずれない
  static DateTime? parseDateOnly(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(s);
    if (m != null) {
      return DateTime(
          int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
    }
    return DateTime.tryParse(s);
  }

  /// 'YYYY-MM-DD' に整形する（サーバーの DATE 列へ送る形式）
  static String formatDateOnly(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// その日付が日本時間の今日より未来か（日付単位・当日は未来ではない）
  static bool isAfterToday(DateTime d) => dateOnly(d).isAfter(todayJst());
}
