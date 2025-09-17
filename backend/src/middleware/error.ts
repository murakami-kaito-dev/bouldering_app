import { Request, Response, NextFunction } from 'express';
import logger from '../utils/logger';

// Custom error class
export class ApiError extends Error {
  constructor(
    public statusCode: number,
    public message: string,
    public code?: string,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

// Error handler middleware
export function errorHandler(
  err: Error | ApiError,
  req: Request,
  res: Response,
  next: NextFunction,
): void {
  // Log error
  logger.error('Request error', {
    error: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method,
    body: req.body,
    userId: (req as any).user?.uid,
  });

  // Handle known API errors
  if (err instanceof ApiError) {
    res.status(err.statusCode).json({
      success: false,
      error: err.message,
      code: err.code,
    });
    return;
  }

  // Handle validation errors
  if (err.name === 'ValidationError') {
    res.status(400).json({
      success: false,
      error: 'Validation error',
      details: err.message,
    });
    return;
  }

  // Handle database errors
  if (err.name === 'DatabaseError') {
    res.status(500).json({
      success: false,
      error: 'Database error',
      code: 'DB_ERROR',
    });
    return;
  }

  // Default error response
  res.status(500).json({
    success: false,
    error: 'Internal server error',
    code: 'INTERNAL_ERROR',
  });
}

// Not found handler
export function notFoundHandler(req: Request, res: Response): void {
  res.status(404).json({
    success: false,
    error: 'Resource not found',
    path: req.url,
  });
}