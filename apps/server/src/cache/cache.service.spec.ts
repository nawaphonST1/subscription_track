import { beforeEach, describe, expect, it, vi } from 'vitest';
import { CacheService } from './cache.service';

describe('CacheService', () => {
  let cacheService: CacheService;

  beforeEach(async () => {
    cacheService = new CacheService();
    await cacheService.onModuleInit();
  });

  it('stores and retrieves values from in-memory fallback', async () => {
    await cacheService.set('test:key1', { name: 'Netflix', price: 299 });
    const result = await cacheService.get<{ name: string; price: number }>(
      'test:key1',
    );
    expect(result).toEqual({ name: 'Netflix', price: 299 });
  });

  it('returns null for nonexistent keys', async () => {
    const result = await cacheService.get('nonexistent');
    expect(result).toBeNull();
  });

  it('expires entries after TTL', async () => {
    vi.useFakeTimers();
    try {
      await cacheService.set('test:ttl', 'temp-value', 10); // 10 seconds
      expect(await cacheService.get('test:ttl')).toBe('temp-value');

      // Fast-forward 11 seconds
      vi.advanceTimersByTime(11000);

      expect(await cacheService.get('test:ttl')).toBeNull();
    } finally {
      vi.useRealTimers();
    }
  });

  it('deletes a specific key', async () => {
    await cacheService.set('test:delete', 'value');
    expect(await cacheService.get('test:delete')).toBe('value');

    await cacheService.del('test:delete');
    expect(await cacheService.get('test:delete')).toBeNull();
  });

  it('deletes keys matching a wildcard pattern', async () => {
    await cacheService.set('user:1:profile', { id: '1' });
    await cacheService.set('user:1:scores', { score: 10 });
    await cacheService.set('user:2:profile', { id: '2' });

    await cacheService.delByPattern('user:1:*');

    expect(await cacheService.get('user:1:profile')).toBeNull();
    expect(await cacheService.get('user:1:scores')).toBeNull();
    expect(await cacheService.get('user:2:profile')).toEqual({ id: '2' });
  });

  it('cleans up resources onModuleDestroy', async () => {
    await expect(cacheService.onModuleDestroy()).resolves.toBeUndefined();
  });
});
