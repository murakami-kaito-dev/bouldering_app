/**
 * イベントバスインターface
 * 
 * クリーンアーキテクチャにおける位置づけ:
 * - Domain 層のインターface
 * - イベント配信の抽象化を提供
 * - ドメインイベントの発行と処理を管理
 */

export interface IEventBus {
  /**
   * イベントを発行
   * @param event 発行するドメインイベント
   */
  publish(event: any): Promise<void>;

  /**
   * イベントハンドラーを登録
   * @param eventType イベントタイプ
   * @param handler イベントハンドラー
   */
  subscribe(eventType: string, handler: (event: any) => Promise<void>): void;
}