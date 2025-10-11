import { InMemoryEventBus } from '../events/InMemoryEventBus';
import { StorageCleanupEventHandler } from '../handlers/StorageCleanupEventHandler';
import { TweetService } from '../../services/tweetService';
import { UserService } from '../../services/userService';
import { GymService } from '../../services/gymService';
import { FavoriteService } from '../../services/favoriteService';
import { PostgresTweetRepository } from '../repositories/PostgresTweetRepository';
import { PostgresUserRepository } from '../repositories/PostgresUserRepository';
import { PostgresGymRepository } from '../repositories/PostgresGymRepository';
import { PostgresFavoriteRepository } from '../repositories/PostgresFavoriteRepository';
import { PostgresReportRepository } from '../repositories/PostgresReportRepository';
import { ReportService } from '../../services/reportService';
import { PostgresBlockRepository } from '../repositories/PostgresBlockRepository';
import { BlockService } from '../../services/blockService';
import logger from '../../utils/logger';

/**
 * 依存性注入セットアップ
 * 
 * クリーンアーキテクチャにおける位置づけ:
 * - Infrastructure 層の設定ファイル
 * - 具体的な依存性の組み立てを担当
 * - アプリケーション起動時に一度だけ実行
 * 
 * 責務:
 * - イベントバスのセットアップ
 * - イベントハンドラーの登録
 * - サービスクラスへの依存性注入
 */

// シングルトンインスタンス
let eventBus: InMemoryEventBus | null = null;
let tweetServiceInstance: TweetService | null = null;
let userServiceInstance: UserService | null = null;
let gymServiceInstance: GymService | null = null;
let favoriteServiceInstance: FavoriteService | null = null;
let reportServiceInstance: ReportService | null = null;
let blockServiceInstance: BlockService | null = null;

// リポジトリインスタンス
let tweetRepository: PostgresTweetRepository | null = null;
let userRepository: PostgresUserRepository | null = null;
let gymRepository: PostgresGymRepository | null = null;
let favoriteRepository: PostgresFavoriteRepository | null = null;
let reportRepository: PostgresReportRepository | null = null;
let blockRepository: PostgresBlockRepository | null = null;

/**
 * リポジトリインスタンスを取得
 */
function getTweetRepository(): PostgresTweetRepository {
  if (!tweetRepository) {
    tweetRepository = new PostgresTweetRepository();
  }
  return tweetRepository;
}

function getUserRepository(): PostgresUserRepository {
  if (!userRepository) {
    userRepository = new PostgresUserRepository();
  }
  return userRepository;
}

function getGymRepository(): PostgresGymRepository {
  if (!gymRepository) {
    gymRepository = new PostgresGymRepository();
  }
  return gymRepository;
}

function getFavoriteRepository(): PostgresFavoriteRepository {
  if (!favoriteRepository) {
    favoriteRepository = new PostgresFavoriteRepository();
  }
  return favoriteRepository;
}

function getReportRepository(): PostgresReportRepository {
  if (!reportRepository) {
    reportRepository = new PostgresReportRepository();
  }
  return reportRepository;
}

function getBlockRepository(): PostgresBlockRepository {
  if (!blockRepository) {
    blockRepository = new PostgresBlockRepository();
  }
  return blockRepository;
}

/**
 * イベントバスとハンドラーのセットアップ
 */
export function setupEventSystem(): InMemoryEventBus {
  if (eventBus) {
    return eventBus;
  }

  logger.info('Setting up event system...');

  // イベントバスの初期化
  eventBus = new InMemoryEventBus();

  // ストレージクリーンアップハンドラーの登録
  const storageCleanupHandler = new StorageCleanupEventHandler();
  eventBus.subscribe('TweetDeleted', (event) => storageCleanupHandler.handle(event));

  logger.info('Event system setup completed', {
    eventBus: 'InMemoryEventBus',
    registeredHandlers: eventBus.getHandlerInfo()
  });

  return eventBus;
}

/**
 * TweetServiceの依存性注入済みインスタンスを取得
 */
export function getTweetService(): TweetService {
  if (tweetServiceInstance) {
    return tweetServiceInstance;
  }

  // イベントシステムのセットアップ
  const eventBusInstance = setupEventSystem();

  // リポジトリとイベントバスを注入してTweetServiceを作成
  const tweetRepo = getTweetRepository();
  tweetServiceInstance = new TweetService(tweetRepo, eventBusInstance);

  logger.info('TweetService initialized with Clean Architecture', {
    hasEventBus: true,
    hasRepository: true
  });

  return tweetServiceInstance;
}

/**
 * UserServiceの依存性注入済みインスタンスを取得
 */
export function getUserService(): UserService {
  if (userServiceInstance) {
    return userServiceInstance;
  }

  // イベントシステムのセットアップ
  const eventBusInstance = setupEventSystem();

  // リポジトリとイベントバスを注入してUserServiceを作成
  const userRepo = getUserRepository();
  userServiceInstance = new UserService(userRepo, eventBusInstance);

  logger.info('UserService initialized with Clean Architecture', {
    hasEventBus: true,
    hasRepository: true
  });

  return userServiceInstance;
}

/**
 * GymServiceの依存性注入済みインスタンスを取得
 */
export function getGymService(): GymService {
  if (gymServiceInstance) {
    return gymServiceInstance;
  }

  // イベントシステムのセットアップ
  const eventBusInstance = setupEventSystem();

  // リポジトリとイベントバスを注入してGymServiceを作成
  const gymRepo = getGymRepository();
  gymServiceInstance = new GymService(gymRepo, eventBusInstance);

  logger.info('GymService initialized with Clean Architecture', {
    hasEventBus: true,
    hasRepository: true
  });

  return gymServiceInstance;
}

/**
 * FavoriteServiceの依存性注入済みインスタンスを取得
 */
export function getFavoriteService(): FavoriteService {
  if (favoriteServiceInstance) {
    return favoriteServiceInstance;
  }

  // イベントシステムのセットアップ
  const eventBusInstance = setupEventSystem();

  // リポジトリとイベントバスを注入してFavoriteServiceを作成
  const favoriteRepo = getFavoriteRepository();
  favoriteServiceInstance = new FavoriteService(favoriteRepo, eventBusInstance);

  logger.info('FavoriteService initialized with Clean Architecture', {
    hasEventBus: true,
    hasRepository: true
  });

  return favoriteServiceInstance;
}

/**
 * ReportServiceの依存性注入済みインスタンスを取得
 */
export function getReportService(): ReportService {
  if (reportServiceInstance) {
    return reportServiceInstance;
  }

  // リポジトリを注入してReportServiceを作成
  // 報告機能はイベントバスを使用しない
  const reportRepo = getReportRepository();
  reportServiceInstance = new ReportService(reportRepo);

  logger.info('ReportService initialized', {
    hasRepository: true
  });

  return reportServiceInstance;
}

/**
 * BlockServiceの依存性注入済みインスタンスを取得
 */
export function getBlockService(): BlockService {
  if (blockServiceInstance) {
    return blockServiceInstance;
  }

  // リポジトリを注入してBlockServiceを作成
  // ブロック機能はイベントバスを使用しない
  const blockRepo = getBlockRepository();
  blockServiceInstance = new BlockService(blockRepo);

  logger.info('BlockService initialized', {
    hasRepository: true
  });

  return blockServiceInstance;
}


/**
 * アプリケーション初期化
 * Express アプリケーション起動時に呼び出す
 */
export function initializeApplication(): void {
  logger.info('Initializing application dependencies...');
  
  // イベントシステムのセットアップ
  setupEventSystem();
  
  // 全サービスの初期化
  getTweetService();
  getUserService();
  getGymService();
  getFavoriteService();
  getReportService();
  getBlockService();
  
  logger.info('Application dependencies initialized successfully');
}