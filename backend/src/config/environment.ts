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
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432', 10),
    database: process.env.DB_NAME || 'bouldering_app',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || '',
    // Cloud SQL instance connection name (for production)
    instanceConnectionName: process.env.INSTANCE_CONNECTION_NAME,
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
    required.push('DB_PASSWORD', 'INSTANCE_CONNECTION_NAME');
  }

  const missing = required.filter(key => !process.env[key]);

  if (missing.length > 0) {
    throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
  }
}