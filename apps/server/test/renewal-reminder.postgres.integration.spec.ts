import { PrismaClient, SubscriptionStatus } from '@prisma/client';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import { NotificationsService } from '../src/notifications/notifications.service';
import { PrismaService } from '../src/prisma/prisma.service';

// Same safety philosophy as BE-401's device-registrations.postgres.integration.spec.ts.
// Assumes `prisma migrate deploy` has already been applied to
// BE403_REAL_DATABASE_URL (baseline + BE-401 + BE-403 migrations).
const runRealDatabaseIntegration = process.env.RUN_DB_INTEGRATION === '1';
const describeRealPostgres = runRealDatabaseIntegration
  ? describe
  : describe.skip;

function assertSafeTestDatabaseUrl(databaseUrl: string): void {
  if (process.env.NODE_ENV === 'production') {
    throw new Error(
      'Refusing to run BE-403 PostgreSQL integration tests with NODE_ENV=production',
    );
  }

  let parsed: URL;
  try {
    parsed = new URL(databaseUrl);
  } catch {
    throw new Error('BE403_REAL_DATABASE_URL is not a valid PostgreSQL URL');
  }

  if (parsed.protocol !== 'postgresql:' && parsed.protocol !== 'postgres:') {
    throw new Error(
      'BE403_REAL_DATABASE_URL must use postgres:// or postgresql://',
    );
  }

  const databaseName = decodeURIComponent(parsed.pathname.replace(/^\/+/, ''));
  if (!databaseName) {
    throw new Error('BE403_REAL_DATABASE_URL must specify a database name');
  }

  if (!databaseName.endsWith('_test')) {
    throw new Error(
      'Refusing to run BE-403 PostgreSQL integration tests against a database whose name does not end with _test',
    );
  }
}

describeRealPostgres('BE-403 renewal reminder against real PostgreSQL', () => {
  let prisma: PrismaClient;
  let notificationsService: NotificationsService;
  const userIds: string[] = [];

  async function createUserWithSubscription(suffix: string) {
    const user = await prisma.user.create({
      data: {
        email: `be403-real-${suffix}-${Date.now()}@example.com`,
        password_hash: 'test-password-hash',
        security_pin_hash: 'test-pin-hash',
      },
    });
    userIds.push(user.id);

    const paymentCard = await prisma.paymentCard.create({
      data: {
        user_id: user.id,
        card_nickname: 'Test Card',
        card_brand: 'Visa',
        last_4_digits: '1234',
        bank_name: 'Test Bank',
      },
    });

    const subscription = await prisma.userSubscription.create({
      data: {
        user_id: user.id,
        payment_card_id: paymentCard.id,
        name: 'Netflix',
        category: 'Streaming',
        price: 199,
        start_date: new Date('2026-01-01T00:00:00.000Z'),
        next_renewal_date: new Date('2026-10-08T00:00:00.000Z'),
        status: SubscriptionStatus.ACTIVE,
      },
    });

    return { user, subscription };
  }

  beforeAll(async () => {
    const databaseUrl = process.env.BE403_REAL_DATABASE_URL;
    if (!databaseUrl) {
      throw new Error(
        'BE403_REAL_DATABASE_URL is required when RUN_DB_INTEGRATION=1',
      );
    }
    assertSafeTestDatabaseUrl(databaseUrl);

    prisma = new PrismaClient({ datasources: { db: { url: databaseUrl } } });
    await prisma.$connect();
    notificationsService = new NotificationsService(
      prisma as unknown as PrismaService,
    );
  });

  afterAll(async () => {
    if (!prisma) {
      return;
    }
    if (userIds.length > 0) {
      await prisma.user.deleteMany({ where: { id: { in: userIds } } });
    }
    await prisma.$disconnect();
  });

  it('inserts a Notification with a dedupe_key', async () => {
    const { user, subscription } = await createUserWithSubscription('insert');

    const notification = await notificationsService.ensureRenewalNotification({
      userId: user.id,
      subscriptionId: subscription.id,
      renewalDate: subscription.next_renewal_date,
      title: 'Upcoming renewal',
      message: 'Your Netflix subscription renews in 3 days.',
    });

    const row = await prisma.notification.findUniqueOrThrow({
      where: { id: notification.id },
    });
    expect(row.dedupe_key).toBe(`renewal-${subscription.id}-2026-10-08`);
  });

  it('converges to exactly one Notification row under concurrent duplicate writes', async () => {
    const { user, subscription } = await createUserWithSubscription('race');
    const params = {
      userId: user.id,
      subscriptionId: subscription.id,
      renewalDate: subscription.next_renewal_date,
      title: 'Upcoming renewal',
      message: 'Your Netflix subscription renews in 3 days.',
    };

    const results = await Promise.allSettled([
      notificationsService.ensureRenewalNotification(params),
      notificationsService.ensureRenewalNotification(params),
      notificationsService.ensureRenewalNotification(params),
    ]);

    expect(results.every((r) => r.status === 'fulfilled')).toBe(true);

    const dedupeKey = `renewal-${subscription.id}-2026-10-08`;
    const count = await prisma.notification.count({
      where: { dedupe_key: dedupeKey },
    });
    expect(count).toBe(1);
  });

  it('allows multiple Notification rows with a NULL dedupe_key', async () => {
    const { user } = await createUserWithSubscription('null-dedupe');

    await prisma.notification.createMany({
      data: [
        {
          user_id: user.id,
          title: 'System message A',
          message: 'A',
          type: 'SECURITY_ALERT',
        },
        {
          user_id: user.id,
          title: 'System message B',
          message: 'B',
          type: 'SECURITY_ALERT',
        },
      ],
    });

    const count = await prisma.notification.count({
      where: { user_id: user.id, dedupe_key: null },
    });
    expect(count).toBe(2);
  });

  it('links Notification.subscription_id to the originating UserSubscription', async () => {
    const { user, subscription } = await createUserWithSubscription('link');

    const notification = await notificationsService.ensureRenewalNotification({
      userId: user.id,
      subscriptionId: subscription.id,
      renewalDate: subscription.next_renewal_date,
      title: 'Upcoming renewal',
      message: 'Renews soon',
    });

    const withRelation = await prisma.notification.findUniqueOrThrow({
      where: { id: notification.id },
      include: { subscription: true },
    });
    expect(withRelation.subscription?.id).toBe(subscription.id);
  });

  it('sets subscription_id to NULL (not a cascade delete) when the UserSubscription is deleted', async () => {
    const { user, subscription } = await createUserWithSubscription('set-null');

    const notification = await notificationsService.ensureRenewalNotification({
      userId: user.id,
      subscriptionId: subscription.id,
      renewalDate: subscription.next_renewal_date,
      title: 'Upcoming renewal',
      message: 'Renews soon',
    });

    await prisma.userSubscription.delete({ where: { id: subscription.id } });

    const afterDelete = await prisma.notification.findUniqueOrThrow({
      where: { id: notification.id },
    });
    expect(afterDelete.subscription_id).toBeNull();
    expect(afterDelete.id).toBe(notification.id);
  });

  it('preserves the existing User -> Notification cascade-delete contract', async () => {
    const { user, subscription } = await createUserWithSubscription('cascade');
    await notificationsService.ensureRenewalNotification({
      userId: user.id,
      subscriptionId: subscription.id,
      renewalDate: subscription.next_renewal_date,
      title: 'Upcoming renewal',
      message: 'Renews soon',
    });

    await prisma.user.delete({ where: { id: user.id } });
    userIds.splice(userIds.indexOf(user.id), 1);

    const remaining = await prisma.notification.count({
      where: { user_id: user.id },
    });
    expect(remaining).toBe(0);
  });

  it('never exposes dedupe_key or subscription_id through NotificationsService.findAll', async () => {
    const { user, subscription } =
      await createUserWithSubscription('public-select');
    await notificationsService.ensureRenewalNotification({
      userId: user.id,
      subscriptionId: subscription.id,
      renewalDate: subscription.next_renewal_date,
      title: 'Upcoming renewal',
      message: 'Renews soon',
    });

    const result = await notificationsService.findAll(user.id);

    expect(result.notifications).toHaveLength(1);
    const [notification] = result.notifications as Record<string, unknown>[];
    expect(
      Object.prototype.hasOwnProperty.call(notification, 'dedupe_key'),
    ).toBe(false);
    expect(
      Object.prototype.hasOwnProperty.call(notification, 'subscription_id'),
    ).toBe(false);
  });
});
