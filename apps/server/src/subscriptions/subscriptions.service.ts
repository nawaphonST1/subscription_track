import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateSubscriptionDto } from './dto/create-subscription.dto';
import { UpdateSubscriptionDto } from './dto/update-subscription.dto';
import { QuerySubscriptionDto } from './dto/query-subscription.dto';
import {
  BillingCycle,
  Prisma,
  SubscriptionStatus,
  UsageStatus,
} from '@prisma/client';

@Injectable()
export class SubscriptionsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(userId: string, query: QuerySubscriptionDto) {
    const where: Prisma.UserSubscriptionWhereInput = {
      user_id: userId,
    };

    if (query.status) {
      where.status = query.status;
    }

    if (query.category) {
      where.category = { equals: query.category, mode: 'insensitive' };
    }

    if (query.search) {
      where.name = { contains: query.search, mode: 'insensitive' };
    }

    if (query.usage_status) {
      where.usage_status = query.usage_status;
    }

    const subscriptions = await this.prisma.userSubscription.findMany({
      where,
      orderBy: { next_renewal_date: 'asc' },
      include: {
        payment_card: {
          select: {
            id: true,
            card_nickname: true,
            card_brand: true,
            last_4_digits: true,
            bank_name: true,
          },
        },
      },
    });

    return subscriptions.map((sub) => ({
      id: sub.id,
      name: sub.name,
      category: sub.category,
      price: Number(sub.price),
      billing_cycle: sub.billing_cycle,
      start_date: sub.start_date,
      next_renewal_date: sub.next_renewal_date,
      usage_status: sub.usage_status,
      status: sub.status,
      brand_color: sub.brand_color,
      notes: sub.notes,
      payment_card: sub.payment_card,
      created_at: sub.created_at,
      updated_at: sub.updated_at,
    }));
  }

  async findUpcoming(userId: string, limit = 10) {
    const subscriptions = await this.prisma.userSubscription.findMany({
      where: {
        user_id: userId,
        status: SubscriptionStatus.ACTIVE,
      },
      orderBy: { next_renewal_date: 'asc' },
      take: limit,
      include: {
        payment_card: {
          select: {
            card_nickname: true,
            last_4_digits: true,
            bank_name: true,
          },
        },
      },
    });

    const now = new Date();

    return subscriptions.map((sub) => {
      const diffMs = sub.next_renewal_date.getTime() - now.getTime();
      const daysUntil = Math.ceil(diffMs / (1000 * 60 * 60 * 24));

      return {
        id: sub.id,
        name: sub.name,
        category: sub.category,
        price: Number(sub.price),
        billing_cycle: sub.billing_cycle,
        next_renewal_date: sub.next_renewal_date,
        days_until_renewal: daysUntil,
        brand_color: sub.brand_color,
        payment_card: sub.payment_card,
      };
    });
  }

  async listPresets() {
    const presets = await this.prisma.subscriptionPreset.findMany({
      orderBy: [{ category: 'asc' }, { name: 'asc' }],
    });

    return presets.map((p) => ({
      id: p.id,
      name: p.name,
      category: p.category,
      default_price: Number(p.default_price),
      billing_cycle: p.billing_cycle,
      brand_color: p.brand_color,
      icon_url: p.icon_url,
      description: p.description,
    }));
  }

  async findOne(userId: string, id: string) {
    const sub = await this.prisma.userSubscription.findFirst({
      where: { id, user_id: userId },
      include: {
        payment_card: true,
        preset: true,
      },
    });

    if (!sub) {
      throw new NotFoundException(`Subscription with ID ${id} not found`);
    }

    return {
      id: sub.id,
      name: sub.name,
      category: sub.category,
      price: Number(sub.price),
      billing_cycle: sub.billing_cycle,
      start_date: sub.start_date,
      next_renewal_date: sub.next_renewal_date,
      usage_status: sub.usage_status,
      status: sub.status,
      brand_color: sub.brand_color,
      notes: sub.notes,
      payment_card: {
        id: sub.payment_card.id,
        card_nickname: sub.payment_card.card_nickname,
        card_brand: sub.payment_card.card_brand,
        last_4_digits: sub.payment_card.last_4_digits,
        bank_name: sub.payment_card.bank_name,
        balance: Number(sub.payment_card.balance),
      },
      preset: sub.preset
        ? {
            id: sub.preset.id,
            name: sub.preset.name,
            icon_url: sub.preset.icon_url,
          }
        : null,
      created_at: sub.created_at,
      updated_at: sub.updated_at,
    };
  }

  async create(userId: string, dto: CreateSubscriptionDto) {
    const card = await this.prisma.paymentCard.findFirst({
      where: { id: dto.payment_card_id, user_id: userId, is_active: true },
    });

    if (!card) {
      throw new BadRequestException(
        'The specified payment card does not exist or does not belong to you',
      );
    }

    const startDate = dto.start_date ? new Date(dto.start_date) : new Date();
    const nextRenewal = dto.next_renewal_date
      ? new Date(dto.next_renewal_date)
      : new Date(startDate);

    if (!dto.next_renewal_date) {
      if (dto.billing_cycle === BillingCycle.WEEKLY) {
        nextRenewal.setDate(nextRenewal.getDate() + 7);
      } else if (dto.billing_cycle === BillingCycle.YEARLY) {
        nextRenewal.setFullYear(nextRenewal.getFullYear() + 1);
      } else {
        nextRenewal.setMonth(nextRenewal.getMonth() + 1);
      }
    }

    const sub = await this.prisma.userSubscription.create({
      data: {
        user_id: userId,
        payment_card_id: dto.payment_card_id,
        preset_id: dto.preset_id,
        name: dto.name,
        category: dto.category,
        price: dto.price,
        billing_cycle: dto.billing_cycle,
        start_date: startDate,
        next_renewal_date: nextRenewal,
        usage_status: dto.usage_status ?? UsageStatus.FREQUENT,
        status: SubscriptionStatus.ACTIVE,
        brand_color: dto.brand_color,
        notes: dto.notes,
      },
    });

    return {
      ...sub,
      price: Number(sub.price),
    };
  }

  async update(userId: string, id: string, dto: UpdateSubscriptionDto) {
    const existing = await this.prisma.userSubscription.findFirst({
      where: { id, user_id: userId },
    });

    if (!existing) {
      throw new NotFoundException(`Subscription with ID ${id} not found`);
    }

    if (
      dto.payment_card_id &&
      dto.payment_card_id !== existing.payment_card_id
    ) {
      const card = await this.prisma.paymentCard.findFirst({
        where: { id: dto.payment_card_id, user_id: userId, is_active: true },
      });
      if (!card) {
        throw new BadRequestException('Specified payment card not found');
      }
    }

    const updated = await this.prisma.userSubscription.update({
      where: { id },
      data: {
        payment_card_id: dto.payment_card_id,
        name: dto.name,
        category: dto.category,
        price: dto.price,
        billing_cycle: dto.billing_cycle,
        next_renewal_date: dto.next_renewal_date
          ? new Date(dto.next_renewal_date)
          : undefined,
        usage_status: dto.usage_status,
        status: dto.status,
        brand_color: dto.brand_color,
        notes: dto.notes,
      },
    });

    return {
      ...updated,
      price: Number(updated.price),
    };
  }

  async remove(userId: string, id: string) {
    const existing = await this.prisma.userSubscription.findFirst({
      where: { id, user_id: userId },
    });

    if (!existing) {
      throw new NotFoundException(`Subscription with ID ${id} not found`);
    }

    await this.prisma.userSubscription.delete({
      where: { id },
    });

    return { message: 'Subscription deleted successfully' };
  }
}
