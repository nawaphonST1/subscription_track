import {
  BadRequestException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateSubscriptionDto } from './dto/create-subscription.dto';
import { UpdateSubscriptionDto } from './dto/update-subscription.dto';
import { QuerySubscriptionDto } from './dto/query-subscription.dto';
import { BusinessMetrics } from '../metrics/business.metrics';
import {
  BillingCycle,
  Prisma,
  SubscriptionStatus,
  UsageStatus,
} from '@prisma/client';
import { CacheService } from '../cache/cache.service';
import { parseAvailablePlans } from '../packages/utils/subscription-plan.util';

export interface UserSubscriptionItem {
  id: string;
  name: string;
  category: string;
  price: number;
  plan_tier: string | null;
  shared_members: number;
  price_per_slot: number | null;
  billing_cycle: BillingCycle;
  start_date: Date;
  next_renewal_date: Date;
  usage_status: UsageStatus;
  status: SubscriptionStatus;
  brand_color: string | null;
  notes: string | null;
  payment_card: {
    id: string;
    card_nickname: string;
    card_brand: string;
    last_4_digits: string;
    bank_name: string;
  };
  created_at: Date;
  updated_at: Date;
}

export interface UpcomingSubscriptionItem {
  id: string;
  name: string;
  category: string;
  price: number;
  billing_cycle: BillingCycle;
  next_renewal_date: Date;
  days_until_renewal: number;
  brand_color: string | null;
  payment_card: {
    card_nickname: string;
    last_4_digits: string;
    bank_name: string;
  };
}

@Injectable()
export class SubscriptionsService {
  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly metrics?: BusinessMetrics,
    @Optional() private readonly cacheService?: CacheService,
  ) {}

  private async evictUserSubscriptionCaches(userId: string) {
    if (this.cacheService) {
      if (typeof this.cacheService.delByPattern === 'function') {
        await this.cacheService.delByPattern(
          `cache:user:${userId}:subscriptions:*`,
        );
        await this.cacheService.delByPattern(
          `cache:user:${userId}:upcoming:*`,
        );
      }
      await this.cacheService.del(`cache:user:${userId}:creep-score`);
      await this.cacheService.del(`cache:user:${userId}:profile`);
      await this.cacheService.del(`cache:user:${userId}:cards`);
      await this.cacheService.del(`cache:user:${userId}:savings-optimizer`);
    }
  }

  async findAll(
    userId: string,
    query: QuerySubscriptionDto,
  ): Promise<UserSubscriptionItem[]> {
    const cacheKey = `cache:user:${userId}:subscriptions:${query.status ?? 'all'}:${query.category ?? 'all'}:${query.search ?? 'all'}:${query.usage_status ?? 'all'}`;
    if (this.cacheService) {
      const cached =
        await this.cacheService.get<UserSubscriptionItem[]>(cacheKey);
      if (cached) {
        return cached;
      }
    }

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
      orderBy: [{ next_renewal_date: 'asc' }, { id: 'asc' }],
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

    const result = subscriptions.map((sub) => ({
      id: sub.id,
      name: sub.name,
      category: sub.category,
      price: Number(sub.price),
      plan_tier: sub.plan_tier,
      shared_members: sub.shared_members,
      price_per_slot: sub.price_per_slot ? Number(sub.price_per_slot) : null,
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

    if (this.cacheService) {
      await this.cacheService.set(cacheKey, result, 300);
    }

    return result;
  }

  async findUpcoming(
    userId: string,
    limit = 10,
  ): Promise<UpcomingSubscriptionItem[]> {
    const cacheKey = `cache:user:${userId}:upcoming:${limit}`;
    if (this.cacheService) {
      const cached =
        await this.cacheService.get<UpcomingSubscriptionItem[]>(cacheKey);
      if (cached) {
        return cached;
      }
    }

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

    const result = subscriptions.map((sub) => {
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

    if (this.cacheService) {
      await this.cacheService.set(cacheKey, result, 300);
    }

    return result;
  }

  async listPresets() {
    const cacheKey = 'cache:subscriptions:presets';
    if (this.cacheService) {
      const cached = await this.cacheService.get(cacheKey);
      if (cached) {
        return cached;
      }
    }

    const presets = await this.prisma.subscriptionPreset.findMany({
      orderBy: [{ category: 'asc' }, { name: 'asc' }],
    });

    const result = presets.map((p) => ({
      id: p.id,
      name: p.name,
      category: p.category,
      default_price: Number(p.default_price),
      billing_cycle: p.billing_cycle,
      brand_color: p.brand_color,
      icon_url: p.icon_url,
      description: p.description,
      features: p.features,
      max_slots: p.max_slots,
      available_plans: parseAvailablePlans(p.available_plans),
    }));

    if (this.cacheService) {
      await this.cacheService.set(cacheKey, result, 86400);
    }

    return result;
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
      plan_tier: sub.plan_tier,
      shared_members: sub.shared_members,
      price_per_slot: sub.price_per_slot ? Number(sub.price_per_slot) : null,
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
    const cardId = dto.payment_card_id || dto.card_id;
    if (!cardId) {
      throw new BadRequestException('payment_card_id or card_id is required');
    }

    const card = await this.prisma.paymentCard.findFirst({
      where: { id: cardId, user_id: userId, is_active: true },
    });

    if (!card) {
      throw new BadRequestException(
        'The specified payment card does not exist or does not belong to you',
      );
    }

    let planMaxSlots: number | undefined;

    if (dto.preset_id) {
      const preset = await this.prisma.subscriptionPreset.findUnique({
        where: { id: dto.preset_id },
      });

      if (!preset) {
        throw new NotFoundException(
          `Preset with ID ${dto.preset_id} not found`,
        );
      }

      if (dto.plan_tier) {
        const plan = parseAvailablePlans(preset.available_plans).find(
          (p) => p.tier === dto.plan_tier,
        );

        if (!plan) {
          throw new BadRequestException(
            `Plan tier "${dto.plan_tier}" is not offered by preset "${preset.name}"`,
          );
        }

        planMaxSlots = plan.maxSlots;
      }
    }

    const sharedMembers = dto.shared_members ?? 1;

    if (planMaxSlots !== undefined && sharedMembers > planMaxSlots) {
      throw new BadRequestException(
        `shared_members (${sharedMembers}) exceeds this plan's max_slots (${planMaxSlots})`,
      );
    }

    const pricePerSlot = dto.price / sharedMembers;

    const startDateStr = dto.start_date || dto.first_bill_date;
    const startDate = startDateStr ? new Date(startDateStr) : new Date();
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
        payment_card_id: cardId,
        preset_id: dto.preset_id,
        plan_tier: dto.plan_tier,
        name: dto.name,
        category: dto.category,
        price: dto.price,
        shared_members: sharedMembers,
        price_per_slot: pricePerSlot,
        billing_cycle: dto.billing_cycle,
        start_date: startDate,
        next_renewal_date: nextRenewal,
        usage_status: dto.usage_status ?? UsageStatus.FREQUENT,
        status: SubscriptionStatus.ACTIVE,
        brand_color: dto.brand_color,
        notes: dto.notes,
      },
    });

    this.metrics?.recordSubscriptionCreated();

    await this.evictUserSubscriptionCaches(userId);

    return {
      ...sub,
      price: Number(sub.price),
      price_per_slot: sub.price_per_slot ? Number(sub.price_per_slot) : null,
    };
  }

  async update(userId: string, id: string, dto: UpdateSubscriptionDto) {
    const existing = await this.prisma.userSubscription.findFirst({
      where: { id, user_id: userId },
    });

    if (!existing) {
      throw new NotFoundException(`Subscription with ID ${id} not found`);
    }

    const updatedCardId = dto.payment_card_id || dto.card_id;
    if (updatedCardId && updatedCardId !== existing.payment_card_id) {
      const card = await this.prisma.paymentCard.findFirst({
        where: { id: updatedCardId, user_id: userId, is_active: true },
      });
      if (!card) {
        throw new BadRequestException('Specified payment card not found');
      }
    }

    const updated = await this.prisma.userSubscription.update({
      where: { id },
      data: {
        payment_card_id:
          updatedCardId !== undefined ? updatedCardId : undefined,
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

    this.metrics?.recordSubscriptionUpdated();

    await this.evictUserSubscriptionCaches(userId);

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

    this.metrics?.recordSubscriptionDeleted();

    await this.evictUserSubscriptionCaches(userId);

    return { message: 'Subscription deleted successfully' };
  }
}
