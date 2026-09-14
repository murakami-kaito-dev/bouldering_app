import { Router } from 'express';
import { confirmVerification } from '../services/emailVerificationService';

const router = Router();

/** ブラウザに出す簡素なページ（アプリ外で開かれる） */
function page(title: string, body: string): string {
  return `<!DOCTYPE html><html lang="ja"><head><meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>${title} — イワノボリタイ</title></head>
<body style="font-family:-apple-system,sans-serif;max-width:32em;margin:12vh auto 0;padding:0 1.5em;line-height:1.9;color:#F2F0EA;background:#15171B">
<h1 style="font-size:1.25em">${title}</h1><p>${body}</p>
<p style="color:#9AA0AA;font-size:.9em">この画面は閉じて構いません。アプリの設定画面を開き直すと反映されます。</p>
</body></html>`;
}

// 33. Confirm notification email (public; the link in the verification mail lands here)
router.get('/confirm', async (req, res, next) => {
  try {
    const userId = String(req.query.u || '');
    const token = String(req.query.t || '');
    if (!userId || !/^[0-9a-f]{64}$/.test(token)) {
      res.status(400).type('html').send(page('無効なリンクです', 'リンクが正しくありません。アプリの設定からもう一度お試しください。'));
      return;
    }
    const result = await confirmVerification(userId, token);
    switch (result) {
      case 'ok':
        res.type('html').send(page('メールアドレスを登録しました', 'お知らせの受け取り先として登録が完了しました。'));
        return;
      case 'expired':
        res.status(410).type('html').send(page('リンクの有効期限が切れています', 'アプリの設定からもう一度メールアドレスを登録してください。'));
        return;
      case 'duplicate':
        res.status(409).type('html').send(page('登録できませんでした', 'このメールアドレスは別のアカウントで登録済みです。'));
        return;
      default:
        res.status(400).type('html').send(page('無効なリンクです', 'リンクが正しくないか、すでに使用済みです。アプリの設定からもう一度お試しください。'));
    }
  } catch (error) {
    next(error);
  }
});

export default router;
