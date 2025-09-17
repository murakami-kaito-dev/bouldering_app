import { Pool, PoolConfig } from 'pg';
import { config } from './environment';
import logger from '../utils/logger';

// Database connection pool configuration
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

// Create the connection pool
export const pool = new Pool(poolConfig);

// Database service class for better abstraction
export class DatabaseService {
  /**
   * Execute a query with parameters
   */
  async query<T = any>(text: string, params?: any[]): Promise<T[]> {
    const start = Date.now();
    try {
      const result = await pool.query(text, params);
      const duration = Date.now() - start;
      
      logger.debug('Database query executed', {
        query: text.substring(0, 100),
        duration: `${duration}ms`,
        rows: result.rowCount,
      });
      
      return result.rows;
    } catch (error) {
      logger.error('Database query error', {
        query: text.substring(0, 100),
        error: error instanceof Error ? error.message : 'Unknown error',
      });
      throw error;
    }
  }

  /**
   * Get a client from the pool for transactions
   */
  async getClient() {
    return pool.connect();
  }

  /**
   * Execute a transaction
   */
  async transaction<T>(callback: (client: any) => Promise<T>): Promise<T> {
    const client = await this.getClient();
    try {
      await client.query('BEGIN');
      const result = await callback(client);
      await client.query('COMMIT');
      return result;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Check database connection
   */
  async checkConnection(): Promise<boolean> {
    try {
      await pool.query('SELECT 1');
      logger.info('Database connection successful');
      return true;
    } catch (error) {
      logger.error('Database connection failed', {
        error: error instanceof Error ? error.message : 'Unknown error',
      });
      return false;
    }
  }

  /**
   * Close all database connections
   */
  async close(): Promise<void> {
    await pool.end();
    logger.info('Database connections closed');
  }
}

// Export singleton instance
export const db = new DatabaseService();