import { Pool, PoolConfig } from 'pg';
import { config } from './environment';
import logger from '../utils/logger';

/**
 * Supabase PostgreSQL接続プール作成
 * 
 * クリーンアーキテクチャにおける位置づけ:
 * - Infrastructure 層の具体実装
 * - Supabase PostgreSQLとの接続を管理
 * - PgBouncer（Transaction pooler）経由での効率的な接続プールを提供
 * 
 * PgBouncerについて:
 * - PostgreSQL用コネクションプーラー
 * - 多数のアプリ接続を少数のDB接続に集約
 * - メモリ効率と性能向上を実現
 * - Supabaseでは6543ポート（Transaction pooler）で提供
 */
// Supabase専用の接続設定
export function createSupabasePool(): Pool {
  const poolConfig: PoolConfig = {};

  // 接続文字列が提供されている場合（推奨）
  if (config.database.url) {
    poolConfig.connectionString = config.database.url;
  } else {
    // 個別パラメータで接続
    poolConfig.host = config.database.host;
    poolConfig.port = config.database.port;
    poolConfig.database = config.database.database;
    poolConfig.user = config.database.user;
    poolConfig.password = config.database.password;
  }

  // Supabase必須のSSL設定
  if (config.database.ssl) {
    poolConfig.ssl = {
      rejectUnauthorized: false // 自己署名証明書を許可（証明書検証を緩める）
    };
  }

  // PgBouncer使用時は接続プールを小さめに設定
  // 理由: PgBouncerが既に接続プールを管理しているため
  poolConfig.max = config.database.maxConnections || 10;
  poolConfig.idleTimeoutMillis = 30000;
  poolConfig.connectionTimeoutMillis = 5000;

  logger.info('Supabase connection pool created', {
    database: poolConfig.database || 'from connection string',
    ssl: !!poolConfig.ssl,
  });

  return new Pool(poolConfig);
}