/* イワノボリタイ 規約ページ（利用規約・プライバシーポリシー）の前後比較の証書。
   before = 公開中の旧ページ（GitHub Pages・minima テーマ）の写し／after = 作り直した新ページの写し（同じ本文・新レイアウト＋CSS）。
   本文の文言は変えていない（段落分けと日付表記の統一のみ）。 */
const BT = '/field/iwanoboritai/demo/before/terms.html', AT = '/field/iwanoboritai/demo/after/terms.html';
const BP = '/field/iwanoboritai/demo/before/privacy.html', AP = '/field/iwanoboritai/demo/after/privacy.html';
export default {
  outFile: 'compare.html', width: 1280, port: 8899,
  siteName: 'イワノボリタイ 利用規約・プライバシーポリシー',
  sohyo: '公開中の旧ページは Jekyll の既定テーマそのままで、灰色の薄い文字とリンク色が読みやすさの床（コントラスト比 4.5）を割り、長い条文がひと塊で積まれていました。作り直した新ページは白地に墨色の文字・上部の帯・要点の箱・2 列の目次で構成し、文字段と角丸を絞り、条文を 2 文以内の段落に分けています。3 幅（1280／768／390）すべてで散らかり度 4〜8・破れ 0 の卒業候補です。',
  sohyoMarke: '規約ページは「読んで安心して次へ進む」ためのページなので、売る形は求めません。要点の箱で最初の画面に「何が公開され、何が公開されないか」を出し、末尾に iOS アプリ・Web 版・お問い合わせへの導線を置きました。',
  mitate: [
    { q: 1, dai: '既定テーマの服を脱ぎ、読み物の服に', shiteki: '旧ページはブログ用テーマ（minima）の既定の服のままで、規約という読み物の体裁になっていませんでした。', shohou: '白地・墨色・1 本の差し色の帯だけに絞り、同作者の他アプリの規約ページと同じ読み物の服にしました。' },
    { q: 6, dai: '長い条文の壁', shiteki: '最初の画面から条文が切れ目なく積まれ、どこから読めばよいか分かりませんでした。', shohou: '要点の箱と目次を先頭に置き、条文は 2 文以内・幅 390px で 3 行以内の段落に分けました。' },
  ],
  mitokoro3: '明るい・静か・墨色',
  pages: [
    { slug: 'terms', title: '利用規約（ページ全体）', before: BT, after: AT },
    { slug: 'privacy', title: 'プライバシーポリシー（ページ全体）', before: BP, after: AP },
  ],
  pinCats: [
    { n: 1, sel: 'header.site', label: '上部の帯（サイト名と差し色）' },
    { n: 2, sel: '.note', label: '要点の箱（最初の画面で結論）' },
    { n: 3, sel: '.toc', label: '2 列の目次' },
  ],
  measure: [
    { label: '利用規約（1280×800）', before: BT, after: AT },
    { label: 'プライバシーポリシー（1280×800）', before: BP, after: AP },
  ],
};
