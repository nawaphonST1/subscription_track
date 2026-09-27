import { Injectable, NotFoundException } from '@nestjs/common';
import { NotificationType, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { buildRenewalDedupeKey } from './renewal-reminder/renewal-reminder.policy';

function isDedupeKeyUniqueConflict(error: unknown): boolean {
  if (
    !(error instanceof Prisma.PrismaClientKnownRequestError) ||
    error.code !== 'P2002'
  ) {
    return false;
  }

  if (error.meta?.modelName !== 'Notification') {
    return false;
  }

  const target = error.meta?.target;
  return (
    (Array.isArray(target) &&
      target.length === 1 &&
      target[0] === 'dedupe_key') ||
    target === 'dedupe_key'
  );
}

// Excludes dedupe_key (never public) and subscription_id (not part of the
// documented public Notification response contract) so BE-403's internal
// worker-facing fields never leak through the public GET/PATCH endpoints.
const PUBLIC_NOTIFICATION_SELECT = {
  id: true,
  user_id: true,
  title: true,
  message: true,
  type: true,
  is_read: true,
  created_at: true,
  updated_at: true,
} satisfies Prisma.NotificationSelect;

@Injectable()
export class NotificationsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(userId: string) {
    const notifications = await this.prisma.notification.findMany({
      where: { user_id: userId },
      orderBy: { created_at: 'desc' },
      select: PUBLIC_NOTIFICATION_SELECT,
    });

    const unreadCount = await this.prisma.notification.count({
      where: { user_id: userId, is_read: false },
    });

    return {
      unread_count: unreadCount,
      notifications,
    };
  }

  async markAsRead(userId: string, id: string) {
    const notification = await this.prisma.notification.findFirst({
      where: { id, user_id: userId },
    });

    if (!notification) {
      throw new NotFoundException(`Notification with ID ${id} not found`);
    }

    const updated = await this.prisma.notification.update({
      where: { id },
      data: { is_read: true },
      select: PUBLIC_NOTIFICATION_SELECT,
    });

    return updated;
  }

  async markAllAsRead(userId: string) {
    const result = await this.prisma.notification.updateMany({
      where: { user_id: userId, is_read: false },
      data: { is_read: true },
    });

    return {
      message: 'All notifications marked as read',
      updated_count: result.count,
    };
  }

  /**
   * Ensures exactly one durable Notification exists for a given subscription
   * renewal occurrence (idempotent via the `dedupe_key` unique constraint).
   *
   * IMPORTANT: an existing Notification row must NEVER be treated as "push
   * already succeeded". This method only guarantees a single durable
   * occurrence in PostgreSQL; the caller (RenewalReminderProcessor) always
   * attempts push delivery afterward, on every retry, regardless of whether
   * the Notification already existed.
   */
  async ensureRenewalNotification(params: {
    userId: string;
    subscriptionId: string;
    renewalDate: Date;
    title: string;
    message: string;
  }): Promise<{ id: string }> {
    const dedupeKey = buildRenewalDedupeKey(
      params.subscriptionId,
      params.renewalDate,
    );

    try {
      return await this.prisma.notification.upsert({
        where: { dedupe_key: dedupeKey },
        update: {},
        create: {
          user_id: params.userId,
          subscription_id: params.subscriptionId,
          dedupe_key: dedupeKey,
          type: NotificationType.RENEWAL_ALERT,
          title: params.title,
          message: params.message,
        },
        select: { id: true },
      });
    } catch (error) {
      if (isDedupeKeyUniqueConflict(error)) {
        return this.prisma.notification.findUniqueOrThrow({
          where: { dedupe_key: dedupeKey },
          select: { id: true },
        });
      }
      throw error;
    }
  }
}
