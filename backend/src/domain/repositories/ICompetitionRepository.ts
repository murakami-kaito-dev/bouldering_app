/**
 * コンペティションリポジトリインターフェース
 *
 * クリーンアーキテクチャにおける位置づけ:
 * - Domain 層のインターフェース
 * - コンペ・参加・完登記録のデータアクセスを抽象化する
 * - インフラストラクチャの詳細（SQL・テーブル名）に依存しない
 *
 * 日付はすべて JST の 'YYYY-MM-DD' 文字列で受け渡す（DATE 列。時刻を付けない）
 */

/** コンペの開催状態（JST の今日と期間を比べて決める） */
export type CompetitionStatus = 'upcoming' | 'active' | 'ended';

/** API に返すコンペ 1 件（ジム名・参加人数・本人との関係を含む） */
export interface CompetitionRow {
  competition_id: number;
  gym_id: number;
  gym_name: string;
  prefecture: string | null;
  host_user_id: string;
  title: string;
  start_date: string; // 'YYYY-MM-DD'（JST）
  end_date: string;   // 'YYYY-MM-DD'（JST）。この日の 23:59:59 まで
  problem_from: number;
  problem_to: number;
  entry_fee_yen: number;
  status: CompetitionStatus;
  participant_count: number;
  /** 認証ユーザーが参加済みか（未認証なら false） */
  is_joined: boolean;
  /** 認証ユーザーが開催者（host または そのジムの管理者）か（未認証なら false） */
  is_host: boolean;
  created_at: Date;
  updated_at: Date;
}

/** 作成・更新の入力 */
export interface CompetitionInput {
  title: string;
  start_date: string;
  end_date: string;
  problem_from: number;
  problem_to: number;
  entry_fee_yen: number;
}

/** 順位表の 1 行 */
export interface LeaderboardEntryRow {
  rank: number;
  user_id: string;
  user_name: string;
  user_icon_url: string | null;
  completed_count: number;
  is_me: boolean;
}

/** 順位表の応答 */
export interface LeaderboardResult {
  competition: CompetitionRow;
  entries: LeaderboardEntryRow[];
  /** 認証ユーザーの順位（未参加・未認証なら null） */
  my_rank: number | null;
  /** 認証ユーザーが完登済みの課題番号（未参加・未認証なら空） */
  my_completed_problems: number[];
}

export interface ICompetitionRepository {
  /** ユーザーが管理するジム ID（管理者でなければ null）。ユーザーが居なければ null */
  findManagedGymId(userId: string): Promise<number | null>;

  /** ユーザーのホームジム ID（未設定なら null） */
  findHomeGymId(userId: string): Promise<number | null>;

  /**
   * 開催中（JST の今日が期間内）のコンペ一覧。
   * homeGymId を渡すと、そのジムのコンペを先頭に並べる
   */
  findActive(today: string, viewerUserId: string | null, homeGymId: number | null): Promise<CompetitionRow[]>;

  /** 開催者として関わるコンペ一覧（host_user_id が本人、または本人の管理ジムのもの）。新しい順 */
  findHosted(today: string, userId: string, managedGymId: number | null): Promise<CompetitionRow[]>;

  /** 参加中（参加済み）のコンペ一覧。開催中 → 開催前 → 終了の順、同じ状態内は終了日の近い順 */
  findJoined(today: string, userId: string): Promise<CompetitionRow[]>;

  /** 1 件取得（無ければ null） */
  findById(competitionId: number, today: string, viewerUserId: string | null): Promise<CompetitionRow | null>;

  /** 作成。作成後の行を返す */
  create(gymId: number, hostUserId: string, input: CompetitionInput, today: string): Promise<CompetitionRow>;

  /** 更新（全項目を上書き）。更新後の行を返す。@throws ApiError(404) */
  update(competitionId: number, input: CompetitionInput, today: string, viewerUserId: string): Promise<CompetitionRow>;

  /** 参加（冪等）。今回新しく参加したか */
  join(competitionId: number, userId: string): Promise<boolean>;

  /** 参加済みか */
  isJoined(competitionId: number, userId: string): Promise<boolean>;

  /** 順位表 */
  getLeaderboard(competitionId: number, today: string, viewerUserId: string | null): Promise<LeaderboardResult | null>;

  /** 完登を記録（冪等） */
  markCompleted(competitionId: number, userId: string, problemNo: number): Promise<void>;

  /** 完登を取り消す（冪等） */
  unmarkCompleted(competitionId: number, userId: string, problemNo: number): Promise<void>;

  /** 本人の完登済み課題番号（昇順） */
  findMyCompletedProblems(competitionId: number, userId: string): Promise<number[]>;

  /**
   * 【開発用】コンペを物理削除する（参加・完登記録は FK の CASCADE で消える）。削除できたか
   * 仕様の「中止」ではない。テストデータの掃除用で、サービス層が COMPETITION_DEBUG_DELETE_ENABLED で門を閉じる
   */
  deleteById(competitionId: number): Promise<boolean>;
}
