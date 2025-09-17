import winston from 'winston';
import { config } from '../config/environment';

// Define log format
const logFormat = winston.format.combine(
  winston.format.timestamp({
    format: 'YYYY-MM-DD HH:mm:ss',
  }),
  winston.format.errors({ stack: true }),
  winston.format.splat(),
  winston.format.json(),
);

// Create logger instance
const logger = winston.createLogger({
  level: config.logging.level,
  format: logFormat,
  defaultMeta: { service: 'bouldering-api' },
  transports: [
    // Console transport
    new winston.transports.Console({
      format: config.server.isDevelopment
        ? winston.format.combine(
            winston.format.colorize(),
            winston.format.simple(),
          )
        : logFormat,
    }),
  ],
});

// Add file transport in production
if (config.server.isProduction) {
  logger.add(
    new winston.transports.File({
      filename: 'logs/error.log',
      level: 'error',
    }),
  );
  logger.add(
    new winston.transports.File({
      filename: 'logs/combined.log',
    }),
  );
}

export default logger;