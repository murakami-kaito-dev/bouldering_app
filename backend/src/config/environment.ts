import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Environment configuration
export const config = {
  // Server
  server: {
    port: parseInt(process.env.PORT || '8080', 10),
    env: process.env.NODE_ENV || 'development',
    isProduction: process.env.NODE_ENV === 'production',
    isDevelopment: process.env.NODE_ENV === 'development',
  },

  // Database
  database: {
    // プロバイダー選択（cloudsql または supabase）
    provider: process.env.DB_PROVIDER || 'supabase',

    // 接続URL（Supabase推奨）
    url: process.env.DATABASE_URL,

    // 個別接続パラメータ
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432', 10),
    database: process.env.DB_NAME || 'bouldering_app',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || '',

    // Cloud SQL専用
    instanceConnectionName: process.env.INSTANCE_CONNECTION_NAME,

    // Supabase専用
    ssl: process.env.DB_SSL === 'true',
    maxConnections: parseInt(process.env.DB_POOL_MAX || '10', 10),
  },

  // Firebase
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID || '',
  },

  // CORS
  cors: {
    origins: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
  },

  // Logging
  logging: {
    level: process.env.LOG_LEVEL || 'info',
  },
} as const;

// Validate required environment variables
export function validateEnvironment(): void {
  const required = [
    'FIREBASE_PROJECT_ID',
  ];

  if (config.server.isProduction) {
    const provider = config.database.provider;

    if (provider === 'cloudsql') {
      required.push('DB_PASSWORD', 'INSTANCE_CONNECTION_NAME');
    } else if (provider === 'supabase') {
      // DATABASE_URLがある場合は個別パラメータ不要
      if (!config.database.url) {
        required.push('DB_HOST', 'DB_PORT', 'DB_NAME', 'DB_USER', 'DB_PASSWORD');
      }
    }
  }

  const missing = required.filter((key) => !process.env[key]);
  if (missing.length > 0) {
    throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
  }
}