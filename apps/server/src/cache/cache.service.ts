import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import Redis from 'ioredis';

interface MemoryCacheEntry {
  value: string;
  expiresAt: number | null;
}

@Injectable()
export class CacheService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(CacheService.name);
  private redisClient: Redis | null = null;
  private readonly memoryStore = new Map<string, MemoryCacheEntry>();
  private memoryCleanupInterval: NodeJS.Timeout | null = null;
  private isRedisReady = false;

  private getErrorMessage(err: unknown): string {
    if (err instanceof Error) {
      return err.message;
    }
    return String(err);
  }

  async onModuleInit() {
    const redisHost = process.env.REDIS_HOST;
    const redisPort = process.env.REDIS_PORT
      ? parseInt(process.env.REDIS_PORT, 10)
      : 6379;

    if (redisHost) {
      try {
        this.redisClient = new Redis({
          host: redisHost,
          port: redisPort,
          lazyConnect: true,
          retryStrategy: (times) => {
            if (times > 3) {
              return null;
            }
            return Math.min(times * 200, 1000);
          },
          connectTimeout: 2000,
        });

        this.redisClient.on('connect', () => {
          this.isRedisReady = true;
          this.logger.log(`Connected to Redis at ${redisHost}:${redisPort}`);
        });

        this.redisClient.on('error', (err: Error) => {
          this.isRedisReady = false;
          this.logger.warn(
            `Redis error: ${err.message}. Operating with in-memory fallback.`,
          );
        });

        this.redisClient.on('close', () => {
          this.isRedisReady = false;
        });

        await this.redisClient.connect().catch((err: unknown) => {
          this.logger.warn(
            `Initial Redis connection failed: ${this.getErrorMessage(err)}. Operating with in-memory fallback.`,
          );
          this.isRedisReady = false;
        });
      } catch (err: unknown) {
        this.logger.warn(
          `Redis initialization failed: ${this.getErrorMessage(err)}. Operating with in-memory fallback.`,
        );
        this.isRedisReady = false;
      }
    } else {
      this.logger.log(
        'REDIS_HOST not configured. Operating with in-memory cache.',
      );
    }

    this.memoryCleanupInterval = setInterval(() => {
      this.cleanExpiredMemoryEntries();
    }, 60000);

    if (this.memoryCleanupInterval?.unref) {
      this.memoryCleanupInterval.unref();
    }
  }

  async onModuleDestroy() {
    if (this.memoryCleanupInterval) {
      clearInterval(this.memoryCleanupInterval);
    }
    if (this.redisClient) {
      try {
        await this.redisClient.quit();
      } catch {
        this.redisClient.disconnect();
      }
    }
  }

  async get<T>(key: string): Promise<T | null> {
    if (this.isRedisReady && this.redisClient) {
      try {
        const raw = await this.redisClient.get(key);
        if (raw === null) {
          return null;
        }
        return JSON.parse(raw) as T;
      } catch (err: unknown) {
        this.logger.warn(
          `Redis GET failed for key "${key}": ${this.getErrorMessage(err)}. Checking in-memory fallback.`,
        );
      }
    }

    const entry = this.memoryStore.get(key);
    if (!entry) {
      return null;
    }

    if (entry.expiresAt !== null && Date.now() > entry.expiresAt) {
      this.memoryStore.delete(key);
      return null;
    }

    try {
      return JSON.parse(entry.value) as T;
    } catch {
      return null;
    }
  }

  async set(key: string, value: unknown, ttlSeconds?: number): Promise<void> {
    const serialized = JSON.stringify(value);

    if (this.isRedisReady && this.redisClient) {
      try {
        if (ttlSeconds && ttlSeconds > 0) {
          await this.redisClient.set(key, serialized, 'EX', ttlSeconds);
        } else {
          await this.redisClient.set(key, serialized);
        }
        return;
      } catch (err: unknown) {
        this.logger.warn(
          `Redis SET failed for key "${key}": ${this.getErrorMessage(err)}. Saving to in-memory fallback.`,
        );
      }
    }

    const expiresAt =
      ttlSeconds && ttlSeconds > 0 ? Date.now() + ttlSeconds * 1000 : null;
    this.memoryStore.set(key, { value: serialized, expiresAt });
  }

  async del(key: string): Promise<void> {
    this.memoryStore.delete(key);

    if (this.isRedisReady && this.redisClient) {
      try {
        await this.redisClient.del(key);
      } catch (err: unknown) {
        this.logger.warn(
          `Redis DEL failed for key "${key}": ${this.getErrorMessage(err)}`,
        );
      }
    }
  }

  async delByPattern(pattern: string): Promise<void> {
    const regexPattern = new RegExp('^' + pattern.replace(/\*/g, '.*') + '$');
    for (const key of this.memoryStore.keys()) {
      if (regexPattern.test(key)) {
        this.memoryStore.delete(key);
      }
    }

    if (this.isRedisReady && this.redisClient) {
      try {
        const keys = await this.redisClient.keys(pattern);
        if (keys.length > 0) {
          await this.redisClient.del(...keys);
        }
      } catch (err: unknown) {
        this.logger.warn(
          `Redis DEL by pattern "${pattern}" failed: ${this.getErrorMessage(err)}`,
        );
      }
    }
  }

  private cleanExpiredMemoryEntries(): void {
    const now = Date.now();
    for (const [key, entry] of this.memoryStore.entries()) {
      if (entry.expiresAt !== null && now > entry.expiresAt) {
        this.memoryStore.delete(key);
      }
    }
  }

  clearMemory(): void {
    this.memoryStore.clear();
  }
}
