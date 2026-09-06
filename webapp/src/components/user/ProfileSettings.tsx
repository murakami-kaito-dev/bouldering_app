"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { bff, BffError, useAuth } from "@/lib/auth";
import { todayYmdJst } from "@/lib/gym/hours";
import type { ProfilePatchResult } from "@/app/api/me/profile/route";
import type { SignedUpload } from "@/app/api/uploads/sign/route";
import { GymCombobox, type PickerGym } from "@/components/post/GymCombobox";
import { Avatar } from "@/components/tweet/TweetCard";
import { Button } from "@/components/ui/Button";
import { Container, Eyebrow, Skeleton } from "@/components/ui/Primitives";
import { Tape } from "@/components/ui/Tape";

/** GET /api/me（= GET /users/:uid）の生の形。必要な項目だけ読む */
interface MeRaw {
  user_id: string;
  user_name: string | null;
  user_icon_url: string | null;
  user_introduce: string | null;
  favorite_gym: string | null;
  gender: number | null;
  birthday: string | null;
  boul_start_date: string | null;
  home_gym_id: number | null;
  email: string | null;
}

interface Ymd {
  y: string;
  m: string;
  d: string;
}

const FIELD_LABEL: Record<string, string> = {
  user_name: "ユーザー名",
  introduce: "自己紹介",
  favorite_gym: "好きなジム",
  gender: "性別",
  birthday: "生年月日",
  boul_start_date: "ボルダリングデビュー",
  home_gym_id: "ホームジム",
  user_icon_url: "アイコン画像",
};

const ICON_TYPES = new Set(["image/jpeg", "image/png", "image/webp", "image/heic", "image/heif"]);
const ICON_MAX_BYTES = 10 * 1024 * 1024;

const pad2 = (v: string) => v.padStart(2, "0");
const splitYmd = (v: string | null): Ymd => {
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(v ?? "");
  return m ? { y: m[1], m: String(Number(m[2])), d: String(Number(m[3])) } : { y: "", m: "", d: "" };
};
const joinYmd = (v: Ymd): string | null => (v.y && v.m && v.d ? `${v.y}-${pad2(v.m)}-${pad2(v.d)}` : null);
const isRealDate = (ymd: string) => {
  const [y, m, d] = ymd.split("-").map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d));
  return dt.getUTCFullYear() === y && dt.getUTCMonth() === m - 1 && dt.getUTCDate() === d;
};

/** 設定画面（/me/settings）: プロフィール / ユーザー設定 の 2 節。変わった項目だけ 1 回の PATCH で送る */
export function ProfileSettings({ gyms }: { gyms: PickerGym[] }) {
  const router = useRouter();
  const { user, getIdToken } = useAuth();

  const [initial, setInitial] = useState<MeRaw | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);

  const [name, setName] = useState("");
  const [introduce, setIntroduce] = useState("");
  const [favoriteGym, setFavoriteGym] = useState("");
  const [gender, setGender] = useState<0 | 1 | 2>(0);
  const [birthday, setBirthday] = useState<Ymd>({ y: "", m: "", d: "" });
  const [debut, setDebut] = useState<Ymd>({ y: "", m: "", d: "1" });
  const [homeGym, setHomeGym] = useState<PickerGym | null>(null);
  const [iconFile, setIconFile] = useState<File | null>(null);
  // プレビュー URL は iconFile から導出し、差し替え／破棄時に revoke する
  const iconPreview = useMemo(() => (iconFile ? URL.createObjectURL(iconFile) : null), [iconFile]);
  useEffect(() => {
    return () => {
      if (iconPreview) URL.revokeObjectURL(iconPreview);
    };
  }, [iconPreview]);
  const fileInput = useRef<HTMLInputElement>(null);

  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);
  const [failed, setFailed] = useState<Array<{ field: string; message: string }>>([]);
  const [done, setDone] = useState(false);

  const today = todayYmdJst();
  const thisYear = Number(today.slice(0, 4));
  const years = useMemo(() => Array.from({ length: thisYear - 1930 + 1 }, (_, i) => String(thisYear - i)), [thisYear]);
  const months = useMemo(() => Array.from({ length: 12 }, (_, i) => String(i + 1)), []);
  const days = useMemo(() => Array.from({ length: 31 }, (_, i) => String(i + 1)), []);

  // 本人データの読込（BFF 経由・要トークン）
  useEffect(() => {
    let cancelled = false;
    getIdToken()
      .then((token) => {
        if (!token) throw new BffError(401, "ログインの有効期限が切れました。もう一度ログインしてください。");
        return bff<MeRaw>("/api/me", { token });
      })
      .then((me) => {
        if (cancelled) return;
        setInitial(me);
        setName(me.user_name ?? "");
        setIntroduce(me.user_introduce ?? "");
        setFavoriteGym(me.favorite_gym ?? "");
        setGender(me.gender === 1 || me.gender === 2 ? me.gender : 0);
        setBirthday(splitYmd(me.birthday));
        const d = splitYmd(me.boul_start_date);
        setDebut({ y: d.y, m: d.m, d: "1" });
        setHomeGym(gyms.find((g) => g.id === me.home_gym_id) ?? null);
      })
      .catch((e: unknown) => {
        if (cancelled) return;
        setLoadError(e instanceof BffError ? e.message : "読み込みに失敗しました。時間をおいて再度お試しください。");
      });
    return () => {
      cancelled = true;
    };
  }, [getIdToken, gyms]);

  const onPickIcon = (f: File | null) => {
    setFormError(null);
    if (!f) return setIconFile(null);
    if (!ICON_TYPES.has(f.type.toLowerCase())) return setFormError("アイコンは JPEG / PNG / WebP / HEIC の画像を選んでください");
    if (f.size > ICON_MAX_BYTES) return setFormError("アイコン画像は 10MB 以下にしてください");
    setIconFile(f);
  };

  const submit = async () => {
    if (!initial || saving) return;
    setFormError(null);
    setFailed([]);

    const patch: Record<string, unknown> = {};
    const trimmedName = name.trim();
    if (trimmedName !== (initial.user_name ?? "")) {
      if (trimmedName.length === 0 || trimmedName.length > 50) return setFormError("ユーザー名は 1〜50 文字で入力してください");
      patch.user_name = trimmedName;
    }
    if (introduce !== (initial.user_introduce ?? "")) {
      if (introduce.length > 500) return setFormError("自己紹介は 500 文字以内で入力してください");
      patch.introduce = introduce;
    }
    if (favoriteGym !== (initial.favorite_gym ?? "")) {
      if (favoriteGym.length > 500) return setFormError("好きなジムは 500 文字以内で入力してください");
      patch.favorite_gym = favoriteGym;
    }
    const initialGender = initial.gender === 1 || initial.gender === 2 ? initial.gender : 0;
    if (gender !== initialGender) patch.gender = gender;

    const b = joinYmd(birthday);
    const anyBirthday = birthday.y || birthday.m || birthday.d;
    if (anyBirthday && !b) return setFormError("生年月日は年・月・日をすべて選んでください");
    if (b && b !== (initial.birthday ?? "").slice(0, 10)) {
      if (!isRealDate(b)) return setFormError("生年月日が実在しない日付です");
      if (b > today) return setFormError("生年月日に未来の日付は指定できません");
      patch.birthday = b;
    }
    const dbt = debut.y && debut.m ? `${debut.y}-${pad2(debut.m)}-01` : null;
    if ((debut.y || debut.m) && !dbt) return setFormError("ボルダリングデビューは年・月を選んでください");
    if (dbt && dbt !== (initial.boul_start_date ?? "").slice(0, 10)) {
      if (dbt > today) return setFormError("ボルダリングデビューに未来の月は指定できません");
      patch.boul_start_date = dbt;
    }
    if (homeGym && homeGym.id !== initial.home_gym_id) patch.home_gym_id = homeGym.id;

    setSaving(true);
    try {
      const token = await getIdToken();
      if (!token) throw new BffError(401, "ログインの有効期限が切れました。もう一度ログインしてください。");

      // アイコン: 署名付き URL を取って GCS へ直接 PUT → 固定パスなので ?v= でキャッシュを破る
      if (iconFile) {
        let signed: SignedUpload;
        try {
          signed = await bff<SignedUpload>("/api/uploads/sign", {
            method: "POST",
            token,
            body: { kind: "icon", content_type: iconFile.type.toLowerCase(), file_name: iconFile.name },
          });
        } catch (e) {
          const msg = e instanceof BffError && (e.status === 404 || e.status >= 500) ? "アイコンのアップロードは準備中です。他の項目は保存できます" : e instanceof BffError ? e.message : "アイコンのアップロードに失敗しました";
          setSaving(false);
          return setFormError(msg);
        }
        const put = await fetch(signed.upload_url, { method: "PUT", headers: { "Content-Type": iconFile.type.toLowerCase() }, body: iconFile });
        if (!put.ok) {
          setSaving(false);
          return setFormError("アイコン画像の送信に失敗しました。時間をおいて再度お試しください");
        }
        patch.user_icon_url = `${signed.public_url}?v=${Date.now()}`;
      }

      if (Object.keys(patch).length === 0) {
        setSaving(false);
        return setFormError("変更された項目がありません");
      }

      const result = await bff<ProfilePatchResult>("/api/me/profile", { method: "PATCH", token, body: patch });
      if (result.failed.length > 0) {
        setFailed(result.failed);
        setSaving(false);
        return;
      }
      setDone(true);
      router.push("/me");
    } catch (e) {
      setFormError(e instanceof BffError ? e.message : "保存に失敗しました。時間をおいて再度お試しください");
      setSaving(false);
    }
  };

  if (loadError) {
    return (
      <Container narrow className="flex flex-col gap-4 py-12">
        <Eyebrow>SETTINGS</Eyebrow>
        <h1 className="text-h1">設定</h1>
        <p role="alert" className="rounded-card border border-hold-red/40 bg-hold-red/10 px-4 py-3 text-small text-hold-red">
          {loadError}
        </p>
        <Link href="/login?next=/me/settings" className="pressable w-fit rounded-pill bg-wall px-5 py-2 text-[14px] font-bold text-wall-ink hover:bg-wall-bright">
          ログインし直す
        </Link>
      </Container>
    );
  }

  if (!initial) {
    return (
      <Container narrow className="flex flex-col gap-6 py-12" aria-busy="true">
        <Skeleton className="h-9 w-40" />
        <Skeleton className="h-24 w-full" />
        <Skeleton className="h-64 w-full" />
      </Container>
    );
  }

  const currentIcon = iconPreview ?? initial.user_icon_url ?? user?.photoURL ?? null;

  return (
    <Container narrow className="flex flex-col gap-10 py-10 md:py-12">
      <div className="flex flex-col gap-2">
        <Link href="/me" className="text-eyebrow text-dust hover:text-chalk">
          ← マイページ
        </Link>
        <Eyebrow>SETTINGS</Eyebrow>
        <h1 className="text-h1">設定</h1>
      </div>

      <form
        className="flex flex-col gap-10"
        onSubmit={(e) => {
          e.preventDefault();
          void submit();
        }}
        noValidate
      >
        {/* ───────── プロフィール ───────── */}
        <section className="flex flex-col gap-5" aria-labelledby="sec-profile">
          <SectionTitle id="sec-profile">プロフィール</SectionTitle>

          <Row label="アイコン" visibility="public">
            <div className="flex items-center gap-4">
              <Avatar src={currentIcon} name={name || "？"} size={72} />
              <div className="flex flex-col gap-2">
                <input
                  ref={fileInput}
                  type="file"
                  accept="image/jpeg,image/png,image/webp,image/heic,image/heif"
                  className="sr-only"
                  onChange={(e) => onPickIcon(e.target.files?.[0] ?? null)}
                />
                <Button type="button" variant="secondary" size="sm" onClick={() => fileInput.current?.click()}>
                  アイコン変更
                </Button>
                {iconFile ? (
                  <button type="button" onClick={() => onPickIcon(null)} className="text-small text-dust hover:text-chalk underline underline-offset-4">
                    選び直す（元に戻す）
                  </button>
                ) : null}
              </div>
            </div>
          </Row>

          <Row label="ユーザー名" visibility="public" htmlFor="f-name">
            <input id="f-name" value={name} onChange={(e) => setName(e.target.value)} maxLength={50} autoComplete="nickname" className={inputCls} />
          </Row>

          <Row label="性別" visibility="private">
            <div className="flex flex-wrap gap-5">
              {(
                [
                  [1, "男性"],
                  [2, "女性"],
                  [0, "未選択"],
                ] as const
              ).map(([v, label]) => (
                <label key={v} className="flex cursor-pointer items-center gap-2 text-[15px] text-chalk">
                  <input type="radio" name="gender" value={v} checked={gender === v} onChange={() => setGender(v)} className="h-5 w-5 accent-[#5b8cff]" />
                  {label}
                </label>
              ))}
            </div>
          </Row>

          <Row label="生年月日" visibility="private">
            <div className="flex flex-wrap items-center gap-2">
              <Select aria-label="年" value={birthday.y} onChange={(y) => setBirthday((s) => ({ ...s, y }))} options={years} placeholder="----" />
              <span className="text-dust">年</span>
              <Select aria-label="月" value={birthday.m} onChange={(m) => setBirthday((s) => ({ ...s, m }))} options={months} placeholder="--" />
              <span className="text-dust">月</span>
              <Select aria-label="日" value={birthday.d} onChange={(d) => setBirthday((s) => ({ ...s, d }))} options={days} placeholder="--" />
              <span className="text-dust">日</span>
            </div>
          </Row>

          <Row label="ボルダリングデビュー" visibility="public" hint="ボルダリング歴の計算に使います">
            <div className="flex flex-wrap items-center gap-2">
              <Select aria-label="年" value={debut.y} onChange={(y) => setDebut((s) => ({ ...s, y }))} options={years} placeholder="----" />
              <span className="text-dust">年</span>
              <Select aria-label="月" value={debut.m} onChange={(m) => setDebut((s) => ({ ...s, m }))} options={months} placeholder="--" />
              <span className="text-dust">月</span>
            </div>
          </Row>

          <Row label="ホームジム" visibility="public">
            <div className="flex flex-col gap-2">
              {homeGym ? <p className="text-[15px] text-chalk">{homeGym.name}</p> : <p className="text-small text-dust">未設定</p>}
              <GymCombobox gyms={gyms} value={homeGym} onChange={setHomeGym} />
            </div>
          </Row>

          <Row label="好きなジム" visibility="public" htmlFor="f-fav" hint="自由に書けます（最大 500 文字）">
            <textarea id="f-fav" value={favoriteGym} onChange={(e) => setFavoriteGym(e.target.value)} maxLength={500} rows={3} className={`${inputCls} min-h-[96px] py-3`} />
          </Row>

          <Row label="自己紹介" visibility="public" htmlFor="f-intro" hint={`${introduce.length} / 500`}>
            <textarea id="f-intro" value={introduce} onChange={(e) => setIntroduce(e.target.value)} maxLength={500} rows={5} className={`${inputCls} min-h-[140px] py-3`} />
          </Row>
        </section>

        {/* ───────── ユーザー設定 ───────── */}
        <section className="flex flex-col gap-5" aria-labelledby="sec-user">
          <SectionTitle id="sec-user">ユーザー設定</SectionTitle>

          <Row label="メールアドレス" visibility="private">
            <div className="flex flex-col gap-1">
              <p className="text-[15px] text-chalk">{initial.email ?? <span className="text-dust">未登録</span>}</p>
              <p className="text-small text-dust">メールアドレスの登録・変更は iOS アプリの設定から行えます。</p>
            </div>
          </Row>

          <Row label="ログイン方法" visibility="private">
            <p className="text-[15px] text-chalk">{user?.displayName ? `Google / Apple アカウント（${user.displayName}）` : "Google / Apple アカウント"}</p>
          </Row>
        </section>

        {formError ? (
          <p role="alert" className="rounded-card border border-hold-red/40 bg-hold-red/10 px-4 py-3 text-small text-hold-red">
            {formError}
          </p>
        ) : null}
        {failed.length > 0 ? (
          <div role="alert" className="flex flex-col gap-1 rounded-card border border-hold-red/40 bg-hold-red/10 px-4 py-3 text-small text-hold-red">
            <p>一部の項目を保存できませんでした。もう一度「更新」を押すと、その項目だけ再送します。</p>
            <ul className="list-disc pl-5">
              {failed.map((f) => (
                <li key={f.field}>
                  {FIELD_LABEL[f.field] ?? f.field}: {f.message}
                </li>
              ))}
            </ul>
          </div>
        ) : null}
        {done ? <p className="text-small text-hold-green">更新しました</p> : null}

        <div className="flex justify-center">
          <Button type="submit" size="lg" disabled={saving} className="min-w-[240px]">
            {saving ? "更新中…" : "更新"}
          </Button>
        </div>
      </form>
    </Container>
  );
}

const inputCls =
  "w-full rounded-card border border-crack bg-ledge px-4 py-2.5 font-body text-[16px] text-chalk placeholder:text-dust focus-visible:rounded-card focus-visible:border-wall-bright";

function SectionTitle({ id, children }: { id: string; children: ReactNode }) {
  return (
    <div className="flex flex-col gap-2">
      <span className="tape-rule" aria-hidden="true" />
      <h2 id={id} className="text-h2">
        {children}
      </h2>
    </div>
  );
}

/** 1 行 = 左にラベル＋公開/非公開テープ、右に入力。モバイルは縦積み */
function Row({
  label,
  visibility,
  htmlFor,
  hint,
  children,
}: {
  label: string;
  visibility: "public" | "private";
  htmlFor?: string;
  hint?: string;
  children: ReactNode;
}) {
  const LabelTag = htmlFor ? "label" : "div";
  return (
    <div className="grid gap-3 border-b border-crack pb-5 md:grid-cols-[180px_minmax(0,1fr)] md:gap-6">
      <div className="flex items-center gap-3 md:pt-2">
        <LabelTag htmlFor={htmlFor} className="font-display text-[15px] font-bold text-chalk">
          {label}
        </LabelTag>
        {visibility === "public" ? (
          <Tape tone="wall" filled>
            公開
          </Tape>
        ) : (
          <Tape tone="ash">非公開</Tape>
        )}
      </div>
      <div className="flex min-w-0 flex-col gap-1.5">
        {children}
        {hint ? <p className="text-small text-dust">{hint}</p> : null}
      </div>
    </div>
  );
}

function Select({
  value,
  onChange,
  options,
  placeholder,
  "aria-label": ariaLabel,
}: {
  value: string;
  onChange: (v: string) => void;
  options: string[];
  placeholder: string;
  "aria-label": string;
}) {
  return (
    <select
      aria-label={ariaLabel}
      value={value}
      onChange={(e) => onChange(e.target.value)}
      className="h-11 rounded-card border border-crack bg-ledge px-3 font-numeric text-[16px] text-chalk focus-visible:rounded-card focus-visible:border-wall-bright"
    >
      <option value="">{placeholder}</option>
      {options.map((o) => (
        <option key={o} value={o}>
          {o}
        </option>
      ))}
    </select>
  );
}
