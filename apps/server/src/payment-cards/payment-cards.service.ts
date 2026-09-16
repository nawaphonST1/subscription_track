import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCardDto } from './dto/create-card.dto';
import { UpdateCardDto } from './dto/update-card.dto';
import { LinkMockCardDto } from './dto/link-mock-card.dto';
import { BillingCycle, NotificationType, UsageStatus } from '@prisma/client';

@Injectable()
export class PaymentCardsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(userId: string) {
    const cards = await this.prisma.paymentCard.findMany({
      where: { user_id: userId, is_active: true },
      orderBy: [{ is_default: 'desc' }, { created_at: 'desc' }],
      include: {
        _count: {
          select: { subscriptions: { where: { status: 'ACTIVE' } } },
        },
      },
    });

    return cards.map((card) => ({
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
      created_at: card.created_at,
      updated_at: card.updated_at,
    }));
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

    return this.prisma.$transaction(async (tx) => {
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
  }

  async update(userId: string, cardId: string, dto: UpdateCardDto) {
    const card = await this.prisma.paymentCard.findFirst({
      where: { id: cardId, user_id: userId, is_active: true },
    });

    if (!card) {
      throw new NotFoundException(`Payment card with ID ${cardId} not found`);
    }

    return this.prisma.$transaction(async (tx) => {
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

    return this.prisma.$transaction(async (tx) => {
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
        },
        imported_subscriptions_count: importedSubscriptions.length,
        imported_subscriptions: importedSubscriptions,
      };
    });
  }
}
