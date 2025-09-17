import { Request, Response, NextFunction } from 'express';
import { verifyIdToken } from '../config/firebase';
import logger from '../utils/logger';

// Extend Express Request type to include user
export interface AuthenticatedRequest extends Request {
  user?: {
    uid: string;
    email?: string;
    email_verified?: boolean;
  };
}

/**
 * Authentication middleware to verify Firebase ID tokens
 */
export async function authenticate(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    // Get authorization header
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({
        success: false,
        error: 'Missing or invalid authorization header',
      });
      return;
    }

    // Extract token
    const idToken = authHeader.split(' ')[1];

    if (!idToken) {
      res.status(401).json({
        success: false,
        error: 'Missing ID token',
      });
      return;
    }

    // Verify token
    const decodedToken = await verifyIdToken(idToken);

    // Add user info to request
    (req as AuthenticatedRequest).user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      email_verified: decodedToken.email_verified,
    };

    logger.debug('User authenticated', {
      userId: decodedToken.uid,
      email: decodedToken.email,
    });

    next();
  } catch (error) {
    logger.error('Authentication error', {
      error: error instanceof Error ? error.message : 'Unknown error',
    });

    res.status(401).json({
      success: false,
      error: 'Invalid or expired token',
    });
  }
}

/**
 * Optional authentication middleware
 * Allows requests without authentication but adds user info if token is provided
 */
export async function optionalAuthenticate(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const authHeader = req.headers.authorization;

    if (authHeader && authHeader.startsWith('Bearer ')) {
      const idToken = authHeader.split(' ')[1];

      if (idToken) {
        const decodedToken = await verifyIdToken(idToken);
        (req as AuthenticatedRequest).user = {
          uid: decodedToken.uid,
          email: decodedToken.email,
          email_verified: decodedToken.email_verified,
        };
      }
    }
  } catch (error) {
    // Log error but continue without authentication
    logger.debug('Optional authentication failed', {
      error: error instanceof Error ? error.message : 'Unknown error',
    });
  }

  next();
}