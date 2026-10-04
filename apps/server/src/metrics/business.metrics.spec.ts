import { Registry } from '@prometheus-io/client';
import { beforeEach, describe, expect, it } from 'vitest';

import { BusinessMetrics } from './business.metrics';

describe('Business metrics', () => {
  let registry: Registry;
  let metrics: BusinessMetrics;

  beforeEach(() => {
    registry = new Registry();
    metrics = new BusinessMetrics(registry);
  });

  it('1. counts login outcomes per credential type', async () => {
    metrics.recordLogin('success', 'password');
    metrics.recordLogin('failure', 'password');
    metrics.recordLogin('failure', 'password');
    metrics.recordLogin('success', 'pin');

    const exposition = await registry.metrics();

    expect(exposition).toContain(
      'auth_login_total{result="success",method="password"} 1',
    );
    expect(exposition).toContain(
      'auth_login_total{result="failure",method="password"} 2',
    );
    expect(exposition).toContain(
      'auth_login_total{result="success",method="pin"} 1',
    );
  });

  it('2. counts subscription lifecycle events', async () => {
    metrics.recordSubscriptionCreated();
    metrics.recordSubscriptionCreated();
    metrics.recordSubscriptionUpdated();
    metrics.recordSubscriptionDeleted();

    const exposition = await registry.metrics();

    expect(exposition).toContain('subscriptions_created_total 2');
    expect(exposition).toContain('subscriptions_updated_total 1');
    expect(exposition).toContain('subscriptions_deleted_total 1');
  });

  it('3. exposes no label that could identify a user', async () => {
    metrics.recordLogin('success', 'password');
    metrics.recordSubscriptionCreated();

    const exposition = await registry.metrics();

    // Only the two closed-set labels may appear on these series.
    const labelNames = [
      ...exposition.matchAll(
        /^(?:auth_login|subscriptions_\w+)\w*\{([^}]*)\}/gm,
      ),
    ]
      .flatMap((match) => match[1].split(','))
      .map((pair) => pair.split('=')[0]);

    expect(new Set(labelNames)).toEqual(new Set(['result', 'method']));
  });

  it('4. swallows a failing counter instead of breaking the caller', () => {
    const broken = new BusinessMetrics(new Registry());
    const internals = broken as unknown as { logins: { inc: () => void } };
    internals.logins.inc = () => {
      throw new Error('SYNTHETIC_COUNTER_FAILURE');
    };

    expect(() => broken.recordLogin('success', 'password')).not.toThrow();
  });
});
