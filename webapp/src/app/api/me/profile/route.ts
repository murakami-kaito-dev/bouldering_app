import { apiRequest } from "@/lib/api/client";
import { errorResponse, isResponse, jsonError, jsonOk, readJson, requireAuth } from "@/lib/auth/server";
import { todayYmdJst } from "@/lib/gym/hours";

/**
 * PATCH /api/me/profile — プロフィール編集（Web の設定画面）。
 *
 * ブラウザは「変わった項目だけ」を 1 回の PATCH で送り、ここでバックエンドの各エンドポイントへ振り分ける
 * （iOS アプリの `user_datasource.dart` と同じ呼び分け）:
 *   user_name       → PATCH /users/:uid                 { user_name }
 *   introduce       → PATCH /users/:uid/profile/texts   { description, type: "true" }
 *   favorite_gym    → PATCH /users/:uid/profile/texts   { description, type: "false" }
 *   gender          → PATCH /users/:uid/gender          { gender: 0|1|2 }
 *   birthday        → PATCH /users/:uid/dates           { update_date, is_bouldering_debut: false }
 *   boul_start_date → PATCH /users/:uid/dates           { update_date, is_bouldering_debut: true }
 *   home_gym_id     → PATCH /users/:uid/home-gym        { home_gym_id }
 *   user_icon_url   → PATCH /users/:uid/icon-url        { user_icon_url }
 *
 * 項目ごとに独立して実行し、成功した項目と失敗した項目（日本語メッセージ付き）を返す。
 * 一部が失敗しても他の項目は保存される（アプリの UpdateUserProfileUseCase と同じ考え方）。
 */
interface ProfilePatchBody {
  user_name?: unknown;
  introduce?: unknown;
  favorite_gym?: unknown;
  gender?: unknown;
  birthday?: unknown;
  boul_start_date?: unknown;
  home_gym_id?: unknown;
  user_icon_url?: unknown;
}

export interface ProfilePatchResult {
  ok: string[];
  failed: Array<{ field: string; message: string }>;
}

const YMD = /^\d{4}-\d{2}-\d{2}$/;

export async function PATCH(req: Request) {
  const ctx = requireAuth(req);
  if (isResponse(ctx)) return ctx;
  const body = await readJson<ProfilePatchBody>(req);
  if (!body) return jsonError(400, "リクエストの形式が正しくありません");

  const uid = encodeURIComponent(ctx.uid);
  const today = todayYmdJst();
  const jobs: Array<{ field: string; run: () => Promise<unknown> }> = [];

  if (body.user_name !== undefined) {
    const v = typeof body.user_name === "string" ? body.user_name.trim() : "";
    if (v.length === 0 || v.length > 50) return jsonError(400, "ユーザー名は 1〜50 文字で入力してください", "NAME_INVALID");
    jobs.push({ field: "user_name", run: () => apiRequest(`/users/${uid}`, { method: "PATCH", token: ctx.token, body: { user_name: v } }) });
  }
  if (body.introduce !== undefined) {
    const v = typeof body.introduce === "string" ? body.introduce : "";
    if (v.length > 500) return jsonError(400, "自己紹介は 500 文字以内で入力してください", "INTRODUCE_TOO_LONG");
    jobs.push({
      field: "introduce",
      run: () => apiRequest(`/users/${uid}/profile/texts`, { method: "PATCH", token: ctx.token, body: { description: v, type: "true" } }),
    });
  }
  if (body.favorite_gym !== undefined) {
    const v = typeof body.favorite_gym === "string" ? body.favorite_gym : "";
    if (v.length > 500) return jsonError(400, "好きなジムは 500 文字以内で入力してください", "FAVORITE_TOO_LONG");
    jobs.push({
      field: "favorite_gym",
      run: () => apiRequest(`/users/${uid}/profile/texts`, { method: "PATCH", token: ctx.token, body: { description: v, type: "false" } }),
    });
  }
  if (body.gender !== undefined) {
    const g = Number(body.gender);
    if (![0, 1, 2].includes(g)) return jsonError(400, "性別の値が正しくありません", "GENDER_INVALID");
    jobs.push({ field: "gender", run: () => apiRequest(`/users/${uid}/gender`, { method: "PATCH", token: ctx.token, body: { gender: g } }) });
  }
  for (const [field, isDebut] of [
    ["birthday", false],
    ["boul_start_date", true],
  ] as const) {
    const raw = body[field];
    if (raw === undefined) continue;
    const v = typeof raw === "string" ? raw : "";
    if (!YMD.test(v) || Number.isNaN(Date.parse(v))) return jsonError(400, "日付の形式が正しくありません", "DATE_INVALID");
    if (v > today) return jsonError(400, "未来の日付は指定できません", "DATE_FUTURE");
    jobs.push({
      field,
      run: () => apiRequest(`/users/${uid}/dates`, { method: "PATCH", token: ctx.token, body: { update_date: v, is_bouldering_debut: isDebut } }),
    });
  }
  if (body.home_gym_id !== undefined) {
    const id = Number(body.home_gym_id);
    if (!Number.isInteger(id) || id < 1) return jsonError(400, "ホームジムの指定が正しくありません", "HOME_GYM_INVALID");
    jobs.push({ field: "home_gym_id", run: () => apiRequest(`/users/${uid}/home-gym`, { method: "PATCH", token: ctx.token, body: { home_gym_id: id } }) });
  }
  if (body.user_icon_url !== undefined) {
    const v = typeof body.user_icon_url === "string" ? body.user_icon_url : "";
    if (!/^https:\/\/storage\.googleapis\.com\//.test(v) || v.length > 1000) return jsonError(400, "アイコン画像の URL が正しくありません", "ICON_URL_INVALID");
    jobs.push({ field: "user_icon_url", run: () => apiRequest(`/users/${uid}/icon-url`, { method: "PATCH", token: ctx.token, body: { user_icon_url: v } }) });
  }

  if (jobs.length === 0) return jsonError(400, "変更された項目がありません", "NOTHING_TO_UPDATE");

  const results = await Promise.allSettled(jobs.map((j) => j.run()));
  const out: ProfilePatchResult = { ok: [], failed: [] };
  results.forEach((r, i) => {
    if (r.status === "fulfilled") out.ok.push(jobs[i].field);
    else {
      // 失敗の日本語化は errorResponse と同じ規則を使い、メッセージだけ取り出す
      const res = errorResponse(r.reason);
      out.failed.push({ field: jobs[i].field, message: `${res.status}` === "401" ? "ログインの有効期限が切れました" : "保存に失敗しました" });
    }
  });
  // 全滅で 401 なら 401 を返してログインし直しに誘導する
  if (out.ok.length === 0 && results.every((r) => r.status === "rejected")) {
    return errorResponse((results[0] as PromiseRejectedResult).reason);
  }
  return jsonOk(out);
}
