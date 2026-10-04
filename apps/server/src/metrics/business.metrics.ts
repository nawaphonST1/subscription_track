import { Inject, Injectable } from '@nestjs/common';
import { Counter, Registry } from '@prometheus-io/client';

import { METRICS_REGISTRY } from './metrics.registry';

/** Credential check outcome. A closed set, so the label stays bounded. */
export type LoginResult = 'success' | 'failure';

/**
 * Which credential was checked: the password on POST /auth/login, or the
 * security PIN on POST /users/me/pin/verify. Also a closed set.
 */
export type LoginMethod = 'password' | 'pin';

/**
 * Aggregate business counters. Deliberately aggregate-only: no user id,
 * email, PIN, token or subscription name is ever used as a label value, so
 * a dashboard built on these can never expose who did what.
 *
 * Every increment is wrapped here rather than at the call sites, so a broken
 * metric can never turn into a failed request no matter who calls it.
 */
@Injectable()
export class BusinessMetrics {
  private readonly logins: Counter<'result' | 'method'>;
  private readonly subscriptionsCreated: Counter<string>;
  private readonly subscriptionsUpdated: Counter<string>;
  private readonly subscriptionsDeleted: Counter<string>;

  constructor(@Inject(METRICS_REGISTRY) registry: Registry) {
    this.logins = new Counter({
      name: 'auth_login_total',
      help: 'Credential checks by outcome and credential type',
      labelNames: ['result', 'method'] as const,
      registers: [registry],
    });

    this.subscriptionsCreated = new Counter({
      name: 'subscriptions_created_total',
      help: 'Subscriptions created',
      registers: [registry],
    });

    this.subscriptionsUpdated = new Counter({
      name: 'subscriptions_updated_total',
      help: 'Subscriptions updated',
      registers: [registry],
    });

    this.subscriptionsDeleted = new Counter({
      name: 'subscriptions_deleted_total',
      help: 'Subscriptions deleted',
      registers: [registry],
    });
  }

  recordLogin(result: LoginResult, method: LoginMethod): void {
    this.safely(() => this.logins.inc({ result, method }));
  }

  recordSubscriptionCreated(): void {
    this.safely(() => this.subscriptionsCreated.inc());
  }

  recordSubscriptionUpdated(): void {
    this.safely(() => this.subscriptionsUpdated.inc());
  }

  recordSubscriptionDeleted(): void {
    this.safely(() => this.subscriptionsDeleted.inc());
  }

  private safely(record: () => void): void {
    try {
      record();
    } catch {
      // Metrics are observability, never a precondition for serving a
      // request. Not logged either: a failing counter would otherwise
      // produce one log line per request.
    }
  }
}
