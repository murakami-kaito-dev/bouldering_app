import { Pool, PoolConfig } from 'pg';
import { config } from './environment';
import logger from '../utils/logger';

/**
 * Cloud SQL PostgreSQL接続プール作成
 * 
 * クリーンアーキテクチャにおける位置づけ:
 * - Infrastructure 層の具体実装
 * - Google Cloud SQL PostgreSQLとの接続を管理
 * - Unix Socket接続（本番）とTCP接続（開発）の両方に対応
 */
// Cloud SQL専用の接続設定（既存のdatabase.tsから移動）
export function createCloudSQLPool(): Pool {
  const poolConfig: PoolConfig = {
    user: config.database.user,
    password: config.database.password,
    database: config.database.database,
    port: config.database.port,
    max: 20, // Maximum number of clients in the pool
    idleTimeoutMillis: 30000, // 30 seconds
    connectionTimeoutMillis: 2000, // 2 seconds
  };

  // For Cloud SQL in production
  if (config.server.isProduction && config.database.instanceConnectionName) {
    poolConfig.host = `/cloudsql/${config.database.instanceConnectionName}`;
  } else {
    poolConfig.host = config.database.host;
  }

  logger.info('Cloud SQL connection pool created', {
    database: poolConfig.database,
    host: poolConfig.host,
  });

  return new Pool(poolConfig);
}