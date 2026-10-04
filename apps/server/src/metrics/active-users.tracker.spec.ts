import { Registry } from '@prometheus-io/client';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import {
  ACTIVE_USERS_MAX_ENTRIES,
  ActiveUsersTracker,
  DEFAULT_ACTIVE_USERS_WINDOW_SECONDS,
} from './active-users.tracker';

import type { ConfigService } from '@nestjs/config';

const configFor = (activeUsersWindowSeconds: number): ConfigService =>
  ({
    get: () => ({ activeUsersWindowSeconds }),
  }) as unknown as ConfigService;

describe('Active users tracker', () => {
  let registry: Registry;

  beforeEach(() => {
    registry = new Registry();
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-10-03T12:00:00.000Z'));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('1. counts distinct users, not requests', () => {
    const tracker = new ActiveUsersTracker(registry, configFor(900));

    tracker.record('user-a');
    tracker.record('user-a');
    tracker.record('user-b');

    expect(tracker.countActive()).toBe(2);
  });

  it('2. forgets users once they fall outside the window', () => {
    const tracker = new ActiveUsersTracker(registry, configFor(900));

    tracker.record('user-a');
    vi.advanceTimersByTime(600_000); // 10 min
    tracker.record('user-b');
    vi.advanceTimersByTime(400_000); // user-a is now 16.6 min old

    expect(tracker.countActive()).toBe(1);
  });

  it('3. uses the configured window, falling back to 15 minutes', () => {
    const configured = new ActiveUsersTracker(registry, configFor(60));
    configured.record('user-a');
    vi.advanceTimersByTime(61_000);
    expect(configured.countActive()).toBe(0);

    const fallback = new ActiveUsersTracker(new Registry(), undefined);
    fallback.record('user-b');
    vi.advanceTimersByTime(
      DEFAULT_ACTIVE_USERS_WINDOW_SECONDS * 1000 - 61_000 - 1000,
    );
    expect(fallback.countActive()).toBe(1);
  });

  it('4. never grows past the entry cap and counts what it dropped', async () => {
    const tracker = new ActiveUsersTracker(registry, configFor(900));

    for (let index = 0; index < ACTIVE_USERS_MAX_ENTRIES + 5; index += 1) {
      tracker.record(`user-${index}`);
    }

    expect(tracker.countActive()).toBe(ACTIVE_USERS_MAX_ENTRIES);
    expect(await registry.metrics()).toContain(
      'active_users_tracker_dropped_total 5',
    );
  });

  it('5. publishes the gauge with a bounded window label and no user id', async () => {
    const tracker = new ActiveUsersTracker(registry, configFor(900));
    tracker.record('11111111-2222-3333-4444-555555555555');

    const exposition = await registry.metrics();

    expect(exposition).toContain('active_users{window="900s"} 1');
    expect(exposition).not.toContain('11111111');
  });

  it('6. ignores an empty user id and never throws from record()', () => {
    const tracker = new ActiveUsersTracker(registry, configFor(900));

    expect(() => tracker.record('')).not.toThrow();
    expect(tracker.countActive()).toBe(0);
  });
});
