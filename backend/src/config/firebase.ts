import admin from 'firebase-admin';
import { config } from './environment';
import logger from '../utils/logger';

// Initialize Firebase Admin SDK
export function initializeFirebase(): void {
  try {
    // In production, use Application Default Credentials
    // In development, you can use a service account key file
    if (config.server.isProduction) {
      admin.initializeApp({
        projectId: config.firebase.projectId,
      });
    } else {
      // For development, you can either use:
      // 1. Service account key file (download from Firebase Console)
      // 2. Or use Firebase emulator
      admin.initializeApp({
        projectId: config.firebase.projectId,
      });
    }

    logger.info('Firebase Admin SDK initialized successfully');
  } catch (error) {
    logger.error('Failed to initialize Firebase Admin SDK', {
      error: error instanceof Error ? error.message : 'Unknown error',
    });
    throw error;
  }
}

// Get Firebase Auth instance
export const auth = () => admin.auth();

// Verify ID token
export async function verifyIdToken(token: string): Promise<admin.auth.DecodedIdToken> {
  try {
    const decodedToken = await auth().verifyIdToken(token);
    return decodedToken;
  } catch (error) {
    logger.error('Failed to verify ID token', {
      error: error instanceof Error ? error.message : 'Unknown error',
    });
    throw error;
  }
}