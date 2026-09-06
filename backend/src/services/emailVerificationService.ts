import { createHash, randomBytes } from 'crypto';
import { db } from '../config/database';
import { config } from '../config/environment';
import { ApiError } from '../middleware/error';
import logger from '../utils/logger';

/**
 * 通知用メールアドレスの本人確認（自前送信・Firebase を挟まない）
 *
 * 流れ:
 *  1. requestVerification: 使い捨てトークンを発行し、そのハッシュと有効期限を email_verifications に保存。
 *     Brevo で確認リンク入りのメールを送る（DB の users.email はまだ書かない）
 *  2. confirm: リンクの token を検証し、その時点で users.email に書く（UNIQUE 違反なら duplicate）
 *
 * Firebase の verifyBeforeUpdateEmail を使わないので、再認証もセッション失効も起きない。
 */
export type ConfirmResult = 'ok' | 'invalid' | 'expired' | 'duplicate';

const RESEND_INTERVAL_SEC = 60;

export function isEmailVerificationConfigured(): boolean {
  const e = config.email;
  return Boolean(e.brevoApiKey && e.senderEmail && e.publicBaseUrl);
}

function sha256(s: string): string {
  return createHash('sha256').update(s).digest('hex');
}

/** 確認メールを送る（差出人は Brevo で検証済みのアドレスであること） */
async function sendMail(to: string, subject: string, text: string): Promise<void> {
  const res = await fetch('https://api.brevo.com/v3/smtp/email', {
    method: 'POST',
    headers: { 'api-key': config.email.brevoApiKey, 'content-type': 'application/json' },
    body: JSON.stringify({
      sender: { name: config.email.senderName, email: config.email.senderEmail },
      to: [{ email: to }],
      subject,
      textContent: text,
    }),
  });
  if (!res.ok) {
    const body = (await res.text()).slice(0, 200);
    throw new Error(`brevo ${res.status}: ${body}`);
  }
}

/**
 * 本人確認メールの送信を依頼する
 * 返り値: 'sent' = 送った / 'already_registered' = 既にそのメールで登録済み（何もしない）
 */
export async function requestVerification(userId: string, rawEmail: string): Promise<'sent' | 'already_registered'> {
  if (!isEmailVerificationConfigured()) {
    throw new ApiError(503, 'Email verification is not configured', 'EMAIL_VERIFICATION_UNAVAILABLE');
  }
  const email = rawEmail.trim().toLowerCase();

  // 自分が既にそのメールで登録済みなら何もしない
  const own = await db.query('SELECT email FROM users WHERE user_id = $1', [userId]);
  if (own.length === 0) throw new ApiError(404, 'User not found');
  if ((own[0].email || '').toLowerCase() === email) return 'already_registered';

  // 1アカウント:1メール。別のアカウントが登録済みなら先に断る（確定時にも UNIQUE で守る）
  const dup = await db.query('SELECT 1 FROM users WHERE lower(email) = $1 AND user_id <> $2', [email, userId]);
  if (dup.length > 0) {
    throw new ApiError(409, 'Email is already registered by another account', 'EMAIL_ALREADY_REGISTERED');
  }

  // 連打防止（同じユーザーの再送は 60 秒あける）
  const recent = await db.query(
    'SELECT created_at FROM email_verifications WHERE user_id = $1 AND created_at > NOW() - make_interval(secs => $2)',
    [userId, RESEND_INTERVAL_SEC],
  );
  if (recent.length > 0) {
    throw new ApiError(429, 'Please wait before requesting again', 'TOO_MANY_REQUESTS');
  }

  const token = randomBytes(32).toString('hex');
  await db.query(
    `INSERT INTO email_verifications (user_id, email, token_hash, expires_at, created_at)
     VALUES ($1, $2, $3, NOW() + make_interval(mins => $4), NOW())
     ON CONFLICT (user_id) DO UPDATE
       SET email = EXCLUDED.email, token_hash = EXCLUDED.token_hash,
           expires_at = EXCLUDED.expires_at, created_at = NOW()`,
    [userId, email, sha256(token), config.email.tokenTtlMinutes],
  );

  const link = `${config.email.publicBaseUrl}/email/confirm?u=${encodeURIComponent(userId)}&t=${token}`;
  const hours = Math.round(config.email.tokenTtlMinutes / 60);
  const text =
    'イワノボリタイをご利用いただきありがとうございます。\n\n' +
    'このメールアドレスをお知らせの受け取り先として登録するには、次のリンクを開いてください。\n\n' +
    `${link}\n\n` +
    `このリンクは ${hours} 時間で無効になります。\n` +
    '心当たりがない場合は、このメールを無視してください（登録は行われません）。\n';
  try {
    await sendMail(email, '【イワノボリタイ】メールアドレスの確認', text);
  } catch (e) {
    // 送れなかったら申請自体を取り消す（ユーザーは再度やり直せる）
    await db.query('DELETE FROM email_verifications WHERE user_id = $1', [userId]);
    logger.error('Verification mail failed', { userId, error: e instanceof Error ? e.message : String(e) });
    throw new ApiError(502, 'Failed to send verification email', 'MAIL_SEND_FAILED');
  }
  logger.info('Verification mail sent', { userId });
  return 'sent';
}

/** 確認リンクの着地。token が合えば users.email を書く */
export async function confirmVerification(userId: string, token: string): Promise<ConfirmResult> {
  const rows = await db.query(
    'SELECT email, token_hash, expires_at FROM email_verifications WHERE user_id = $1',
    [userId],
  );
  if (rows.length === 0) return 'invalid';
  const rec = rows[0];
  if (rec.token_hash !== sha256(token)) return 'invalid';
  if (new Date(rec.expires_at).getTime() < Date.now()) {
    await db.query('DELETE FROM email_verifications WHERE user_id = $1', [userId]);
    return 'expired';
  }
  try {
    await db.query('UPDATE users SET email = $1, updated_at = CURRENT_TIMESTAMP WHERE user_id = $2', [rec.email, userId]);
  } catch (e) {
    if (typeof e === 'object' && e !== null && (e as { code?: string }).code === '23505') {
      await db.query('DELETE FROM email_verifications WHERE user_id = $1', [userId]);
      return 'duplicate';
    }
    throw e;
  }
  await db.query('DELETE FROM email_verifications WHERE user_id = $1', [userId]);
  logger.info('Email verified and registered', { userId });
  return 'ok';
}
