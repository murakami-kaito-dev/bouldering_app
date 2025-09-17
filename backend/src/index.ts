import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import compression from 'compression';

import { config, validateEnvironment } from './config/environment';
import { initializeFirebase } from './config/firebase';
import { db } from './config/database';
import logger from './utils/logger';
import { errorHandler, notFoundHandler } from './middleware/error';
import { initializeApplication } from './infrastructure/setup/dependencies';

// Import routes
import userRoutes from './routes/users';
import tweetRoutes from './routes/tweets';
import gymRoutes from './routes/gyms';
import internalTasksRoutes from './routes/internal_tasks';

// Validate environment variables
validateEnvironment();

// Initialize Firebase
initializeFirebase();

// Initialize application dependencies (Clean Architecture setup)
initializeApplication();

// Create Express app
const app = express();

// Middleware
app.use(helmet()); // Security headers
app.use(cors({
  origin: config.cors.origins,
  credentials: true,
}));
app.use(compression()); // Compress responses
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging
if (config.server.isDevelopment) {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined'));
}

// Health check endpoint
app.get('/health', async (req, res) => {
  const dbHealthy = await db.checkConnection();
  
  res.status(dbHealthy ? 200 : 503).json({
    status: dbHealthy ? 'healthy' : 'unhealthy',
    timestamp: new Date().toISOString(),
    database: dbHealthy ? 'connected' : 'disconnected',
  });
});

// API routes
app.use('/api/users', userRoutes);
app.use('/api/tweets', tweetRoutes);
app.use('/api/gyms', gymRoutes);

// Internal task routes (for Cloud Tasks workers)
app.use('/internal/tasks', internalTasksRoutes);

// Error handling
app.use(notFoundHandler);
app.use(errorHandler);

// Start server
async function startServer() {
  try {
    // Check database connection
    await db.checkConnection();

    const server = app.listen(config.server.port, () => {
      logger.info(`Server started on port ${config.server.port}`, {
        environment: config.server.env,
      });
    });

    // Graceful shutdown
    process.on('SIGTERM', async () => {
      logger.info('SIGTERM signal received: closing HTTP server');
      server.close(async () => {
        await db.close();
        logger.info('HTTP server closed');
        process.exit(0);
      });
    });
  } catch (error) {
    logger.error('Failed to start server', {
      error: error instanceof Error ? error.message : 'Unknown error',
    });
    process.exit(1);
  }
}

// Start the server
startServer();

export default app;