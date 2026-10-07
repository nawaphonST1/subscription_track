import {
  ForbiddenException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCardDto } from './dto/create-card.dto';
import { UpdateCardDto } from './dto/update-card.dto';
import { LinkMockCardDto } from './dto/link-mock-card.dto';
import { BillingCycle, NotificationType, UsageStatus } from '@prisma/client';
import { CacheService } from '../cache/cache.service';

export interface PaymentCardItem {
  id: string;
  card_nickname: string;
  card_brand: string;
  card_type: CardType;
  last_4_digits: string;
  bank_name: string;
  balance: number;
  currency: string;
  is_default: boolean;
  active_subscriptions_count: number;
  subscriptions: {
    id: string;
    name: string;
    category: string;
    price: number;
    billing_cycle: BillingCycle;
    next_renewal_date: Date;
    usage_status: UsageStatus;
  }[];
  created_at: Date;
  updated_at: Date;
}

@Injectable()
export class PaymentCardsService {
  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly cacheService?: CacheService,
  ) {}

  private async evictUserCardCaches(
    userId: string,
    evictSubscriptions = false,
  ) {
    if (this.cacheService) {
      await this.cacheService.del(`cache:user:${userId}:cards`);
      await this.cacheService.del(`cache:user:${userId}:creep-score`);
      await this.cacheService.del(`cache:user:${userId}:profile`);
      if (evictSubscriptions) {
        if (typeof this.cacheService.delByPattern === 'function') {
          await this.cacheService.delByPattern(
            `cache:user:${userId}:subscriptions:*`,
          );
          await this.cacheService.delByPattern(
            `cache:user:${userId}:upcoming:*`,
          );
        }
        await this.cacheService.del(`cache:user:${userId}:savings-optimizer`);
      }
    }
  }

  async findAll(userId: string): Promise<PaymentCardItem[]> {
    const cacheKey = `cache:user:${userId}:cards`;
    if (this.cacheService) {
      const cached = await this.cacheService.get<PaymentCardItem[]>(cacheKey);
      if (cached) {
        return cached;
      }
    }

    const cards = await this.prisma.paymentCard.findMany({
      where: { user_id: userId, is_active: true },
      orderBy: [{ is_default: 'desc' }, { created_at: 'desc' }],
      include: {
        subscriptions: {
          where: { status: 'ACTIVE' },
          orderBy: { next_renewal_date: 'asc' },
          select: {
            id: true,
            name: true,
            category: true,
            price: true,
            billing_cycle: true,
            next_renewal_date: true,
            usage_status: true,
          },
        },
        _count: {
          select: { subscriptions: { where: { status: 'ACTIVE' } } },
        },
      },
    });

    const result = cards.map((card) => ({
      id: card.id,
      card_nickname: card.card_nickname,
      card_brand: card.card_brand,
      card_type: card.card_type,
      last_4_digits: card.last_4_digits,
      bank_name: card.bank_name,
      balance: Number(card.balance),
      currency: card.currency,
      is_default: card.is_default,
      active_subscriptions_count: card._count.subscriptions,
      subscriptions: card.subscriptions.map((s) => ({
        id: s.id,
        name: s.name,
        category: s.category,
        price: Number(s.price),
        billing_cycle: s.billing_cycle,
        next_renewal_date: s.next_renewal_date,
        usage_status: s.usage_status,
      })),
      created_at: card.created_at,
      updated_at: card.updated_at,
    }));

    if (this.cacheService) {
      await this.cacheService.set(cacheKey, result, 300);
    }

    return result;
  }

  async findOne(userId: string, cardId: string) {
    const card = await this.prisma.paymentCard.findFirst({
      where: { id: cardId, user_id: userId, is_active: true },
      include: {
        subscriptions: {
          where: { status: 'ACTIVE' },
          orderBy: { next_renewal_date: 'asc' },
        },
      },
    });

    if (!card) {
      throw new NotFoundException(`Payment card with ID ${cardId} not found`);
    }

    return {
      id: card.id,
      card_nickname: card.card_nickname,
      card_brand: card.card_brand,
      card_type: card.card_type,
      last_4_digits: card.last_4_digits,
      bank_name: card.bank_name,
      balance: Number(card.balance),
      currency: card.currency,
      is_default: card.is_default,
      subscriptions: card.subscriptions.map((s) => ({
        id: s.id,
        name: s.name,
        category: s.category,
        price: Number(s.price),
        billing_cycle: s.billing_cycle,
        next_renewal_date: s.next_renewal_date,
        usage_status: s.usage_status,
      })),
      created_at: card.created_at,
      updated_at: card.updated_at,
    };
  }

  async getTotalBalance(userId: string) {
    const cards = await this.prisma.paymentCard.findMany({
      where: { user_id: userId, is_active: true },
      select: { balance: true, currency: true },
    });

    const totalBalance = cards.reduce(
      (acc, card) => acc + Number(card.balance),
      0,
    );

    return {
      total_balance: Number(totalBalance.toFixed(2)),
      currency: cards[0]?.currency || 'THB',
      active_cards_count: cards.length,
    };
  }

  async create(userId: string, dto: CreateCardDto) {
    const existingCount = await this.prisma.paymentCard.count({
      where: { user_id: userId, is_active: true },
    });

    const makeDefault = dto.is_default ?? existingCount === 0;

    const result = await this.prisma.$transaction(async (tx) => {
      if (makeDefault) {
        await tx.paymentCard.updateMany({
          where: { user_id: userId, is_default: true },
          data: { is_default: false },
        });
      }

      const card = await tx.paymentCard.create({
        data: {
          user_id: userId,
          card_nickname: dto.card_nickname,
          card_brand: dto.card_brand,
          card_type: dto.card_type,
          last_4_digits: dto.last_4_digits,
          bank_name: dto.bank_name,
          balance: dto.balance,
          currency: dto.currency ?? 'THB',
          is_default: makeDefault,
        },
      });

      return {
        ...card,
        balance: Number(card.balance),
      };
    });

    await this.evictUserCardCaches(userId);

    return result;
  }

  async update(userId: string, cardId: string, dto: UpdateCardDto) {
    const card = await this.prisma.paymentCard.findFirst({
      where: { id: cardId, user_id: userId, is_active: true },
    });

    if (!card) {
      throw new NotFoundException(`Payment card with ID ${cardId} not found`);
    }

    const result = await this.prisma.$transaction(async (tx) => {
      if (dto.is_default) {
        await tx.paymentCard.updateMany({
          where: { user_id: userId, is_default: true },
          data: { is_default: false },
        });
      }

      const updated = await tx.paymentCard.update({
        where: { id: cardId },
        data: {
          card_nickname: dto.card_nickname,
          balance: dto.balance,
          is_default: dto.is_default,
        },
      });

      return {
        ...updated,
        balance: Number(updated.balance),
      };
    });

    await this.evictUserCardCaches(userId);

    return result;
  }

  async remove(userId: string, cardId: string) {
    const card = await this.prisma.paymentCard.findFirst({
      where: { id: cardId, user_id: userId, is_active: true },
    });

    if (!card) {
      throw new NotFoundException(`Payment card with ID ${cardId} not found`);
    }

    await this.prisma.paymentCard.update({
      where: { id: cardId },
      data: { is_active: false, is_default: false },
    });

    await this.evictUserCardCaches(userId);

    return { message: 'Payment card deactivated successfully' };
  }

  async listMockCards() {
    const mockCards = await this.prisma.mockBankCard.findMany({
      include: {
        subscriptions: true,
      },
      orderBy: { bank_name: 'asc' },
    });

    return mockCards.map((m) => ({
      id: m.id,
      card_nickname: m.card_nickname,
      card_brand: m.card_brand,
      card_type: m.card_type,
      last_4_digits: m.last_4_digits,
      bank_name: m.bank_name,
      balance: Number(m.balance),
      currency: m.currency,
      subscriptions: m.subscriptions.map((s) => ({
        id: s.id,
        name: s.name,
        category: s.category,
        price: Number(s.price),
        billing_cycle: s.billing_cycle,
        brand_color: s.brand_color,
      })),
    }));
  }

  async linkMockCard(userId: string, dto: LinkMockCardDto) {
    const targetId = dto.card_id || dto.mock_card_id;

    if (targetId) {
      const existingPaymentCard = await this.prisma.paymentCard.findUnique({
        where: { id: targetId },
      });

      if (existingPaymentCard) {
        if (existingPaymentCard.user_id !== userId) {
          throw new ForbiddenException(
            'This card does not belong to your account.',
          );
        }

        if (!existingPaymentCard.is_active) {
          await this.prisma.paymentCard.update({
            where: { id: existingPaymentCard.id },
            data: { is_active: true },
          });
        }

        await this.evictUserCardCaches(userId, false);

        return {
          card: {
            id: existingPaymentCard.id,
            card_nickname: existingPaymentCard.card_nickname,
            card_brand: existingPaymentCard.card_brand,
            card_type: existingPaymentCard.card_type,
            last_4_digits: existingPaymentCard.last_4_digits,
            bank_name: existingPaymentCard.bank_name,
            balance: Number(existingPaymentCard.balance),
            currency: existingPaymentCard.currency,
            is_default: existingPaymentCard.is_default,
            subscriptions: [],
          },
          imported_subscriptions_count: 0,
          imported_subscriptions: [],
        };
      }
    }

    let mockCard = null;

    if (dto.mock_card_id) {
      mockCard = await this.prisma.mockBankCard.findUnique({
        where: { id: dto.mock_card_id },
        include: { subscriptions: true },
      });
    } else if (dto.bank_name && dto.last_4_digits) {
      mockCard = await this.prisma.mockBankCard.findFirst({
        where: {
          bank_name: { contains: dto.bank_name, mode: 'insensitive' },
          last_4_digits: dto.last_4_digits,
        },
        include: { subscriptions: true },
      });
    } else {
      mockCard = await this.prisma.mockBankCard.findFirst({
        include: { subscriptions: true },
      });
    }

    if (!mockCard) {
      throw new NotFoundException(
        'No simulated mock bank card found matching criteria',
      );
    }

    const result = await this.prisma.$transaction(async (tx) => {
      const activeCardsCount = await tx.paymentCard.count({
        where: { user_id: userId, is_active: true },
      });

      // 1. Create User Payment Card
      const userCard = await tx.paymentCard.create({
        data: {
          user_id: userId,
          card_nickname: mockCard.card_nickname,
          card_brand: mockCard.card_brand,
          card_type: mockCard.card_type,
          last_4_digits: mockCard.last_4_digits,
          bank_name: mockCard.bank_name,
          balance: mockCard.balance,
          currency: mockCard.currency,
          is_default: activeCardsCount === 0,
        },
      });

      // 2. Clone/Import subscriptions
      const now = new Date();
      const importedSubscriptions = [];

      for (const mockSub of mockCard.subscriptions) {
        const nextRenewal = new Date(now);
        if (mockSub.billing_cycle === BillingCycle.WEEKLY) {
          nextRenewal.setDate(nextRenewal.getDate() + 7);
        } else if (mockSub.billing_cycle === BillingCycle.YEARLY) {
          nextRenewal.setFullYear(nextRenewal.getFullYear() + 1);
        } else {
          nextRenewal.setMonth(nextRenewal.getMonth() + 1);
        }

        // Try to match preset
        const preset = await tx.subscriptionPreset.findFirst({
          where: { name: { contains: mockSub.name, mode: 'insensitive' } },
        });

        const createdSub = await tx.userSubscription.create({
          data: {
            user_id: userId,
            payment_card_id: userCard.id,
            preset_id: preset?.id,
            name: mockSub.name,
            category: mockSub.category,
            price: mockSub.price,
            billing_cycle: mockSub.billing_cycle,
            start_date: now,
            next_renewal_date: nextRenewal,
            usage_status: UsageStatus.FREQUENT,
            brand_color: mockSub.brand_color || preset?.brand_color,
          },
        });

        importedSubscriptions.push({
          id: createdSub.id,
          name: createdSub.name,
          category: createdSub.category,
          price: Number(createdSub.price),
          billing_cycle: createdSub.billing_cycle,
          next_renewal_date: createdSub.next_renewal_date,
        });
      }

      // 3. Create Notification
      await tx.notification.create({
        data: {
          user_id: userId,
          title: 'Card Auto-Import Successful',
          message: `Linked ${userCard.bank_name} card ending in ${userCard.last_4_digits}. Auto-imported ${importedSubscriptions.length} active subscriptions.`,
          type: NotificationType.SECURITY_ALERT,
        },
      });

      return {
        card: {
          id: userCard.id,
          card_nickname: userCard.card_nickname,
          card_brand: userCard.card_brand,
          card_type: userCard.card_type,
          last_4_digits: userCard.last_4_digits,
          bank_name: userCard.bank_name,
          balance: Number(userCard.balance),
          currency: userCard.currency,
          is_default: userCard.is_default,
          subscriptions: importedSubscriptions,
        },
        imported_subscriptions_count: importedSubscriptions.length,
        imported_subscriptions: importedSubscriptions,
      };
    });

    await this.evictUserCardCaches(userId, true);

    return result;
  }
}
