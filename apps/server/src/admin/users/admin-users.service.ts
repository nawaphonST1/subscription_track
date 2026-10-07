import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AdminUserResponseDto } from './dto/admin-user-response.dto';
import { AdminStatsResponseDto } from './dto/admin-stats-response.dto';
import { UpdateAdminUserDto } from './dto/update-admin-user.dto';
import { UpdateSubscriptionDto } from '../../subscriptions/dto/update-subscription.dto';

@Injectable()
export class AdminUsersService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * ดึงภาพรวมสถิติระบบทั้งหมด
   */
  async getStats(): Promise<AdminStatsResponseDto> {
    const [totalUsers, totalSubscriptions, totalCards, totalPackages] =
      await Promise.all([
        this.prisma.user.count(),
        this.prisma.userSubscription.count({ where: { status: 'ACTIVE' } }),
        this.prisma.paymentCard.count({ where: { is_active: true } }),
        this.prisma.subscriptionPreset.count(),
      ]);

    return {
      totalUsers,
      totalSubscriptions,
      totalCards,
      totalPackages,
    };
  }

  /**
   * ดึงรายชื่อผู้ใช้ทั้งหมดในระบบ พร้อมจำนวน Subscription และบัตร
   */
  async getUsers(): Promise<AdminUserResponseDto[]> {
    const users = await this.prisma.user.findMany({
      orderBy: { created_at: 'desc' },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        monthly_income: true,
        created_at: true,
        _count: {
          select: {
            subscriptions: true,
            payment_cards: true,
          },
        },
      },
    });

    return users.map((user) => ({
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      monthlyIncome:
        typeof user.monthly_income === 'number'
          ? user.monthly_income
          : Number(user.monthly_income),
      subscriptionsCount: user._count.subscriptions,
      cardsCount: user._count.payment_cards,
      createdAt: user.created_at,
    }));
  }

  /**
   * ดึงรายละเอียดผู้ใช้รายบุคคล รวมทั้งรายการ Subscription และบัตร
   */
  async getUserDetail(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: {
        subscriptions: {
          orderBy: { created_at: 'desc' },
          include: {
            payment_card: {
              select: {
                id: true,
                card_nickname: true,
                card_brand: true,
                last_4_digits: true,
              },
            },
          },
        },
        payment_cards: {
          orderBy: { created_at: 'desc' },
        },
      },
    });

    if (!user) {
      throw new NotFoundException(`User with ID '${id}' not found`);
    }

    return {
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      monthlyIncome: Number(user.monthly_income),
      createdAt: user.created_at,
      subscriptions: user.subscriptions.map((s) => ({
        id: s.id,
        name: s.name,
        category: s.category,
        price: Number(s.price),
        billingCycle: s.billing_cycle,
        startDate: s.start_date,
        nextRenewalDate: s.next_renewal_date,
        usageStatus: s.usage_status,
        status: s.status,
        brandColor: s.brand_color,
        notes: s.notes,
        planTier: s.plan_tier,
        presetId: s.preset_id,
        paymentCard: s.payment_card
          ? {
              id: s.payment_card.id,
              nickname: s.payment_card.card_nickname,
              brand: s.payment_card.card_brand,
              last4: s.payment_card.last_4_digits,
            }
          : null,
      })),
      paymentCards: user.payment_cards.map((c) => ({
        id: c.id,
        nickname: c.card_nickname,
        brand: c.card_brand,
        last4: c.last_4_digits,
        bankName: c.bank_name,
        balance: Number(c.balance),
        currency: c.currency,
        isActive: c.is_active,
      })),
    };
  }

  /**
   * แก้ไขข้อมูลผู้ใช้ (Admin action)
   */
  async updateUser(
    id: string,
    dto: UpdateAdminUserDto,
  ) {
    const existing = await this.prisma.user.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundException(`User with ID '${id}' not found`);
    }

    const updated = await this.prisma.user.update({
      where: { id },
      data: {
        ...(dto.name !== undefined && { name: dto.name }),
        ...(dto.role !== undefined && { role: dto.role }),
        ...(dto.monthlyIncome !== undefined && {
          monthly_income: dto.monthlyIncome,
        }),
      },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        monthly_income: true,
        created_at: true,
      },
    });

    return {
      id: updated.id,
      email: updated.email,
      name: updated.name,
      role: updated.role,
      monthlyIncome: Number(updated.monthly_income),
      createdAt: updated.created_at,
    };
  }

  /**
   * แก้ไข Subscription ของผู้ใช้ (Admin action)
   */
  async updateSubscription(subId: string, dto: UpdateSubscriptionDto) {
    const existing = await this.prisma.userSubscription.findUnique({
      where: { id: subId },
    });
    if (!existing) {
      throw new NotFoundException(`Subscription with ID '${subId}' not found`);
    }

    const planTier = dto.plan_tier !== undefined ? dto.plan_tier : dto.planTier;
    const presetId = dto.preset_id !== undefined ? dto.preset_id : dto.presetId;
    const cardId = dto.payment_card_id || dto.card_id || dto.paymentCardId;
    const billingCycle = dto.billing_cycle ?? dto.billingCycle;
    const nextRenewalDate = dto.next_renewal_date ?? dto.nextRenewalDate;
    const brandColor = dto.brand_color ?? dto.brandColor;

    const updated = await this.prisma.userSubscription.update({
      where: { id: subId },
      data: {
        ...(dto.name !== undefined && { name: dto.name }),
        ...(dto.category !== undefined && { category: dto.category }),
        ...(dto.price !== undefined && { price: dto.price }),
        ...(billingCycle !== undefined && {
          billing_cycle: billingCycle,
        }),
        ...(dto.status !== undefined && { status: dto.status }),
        ...(nextRenewalDate !== undefined && {
          next_renewal_date: new Date(nextRenewalDate),
        }),
        ...(dto.usage_status !== undefined && {
          usage_status: dto.usage_status,
        }),
        ...(brandColor !== undefined && { brand_color: brandColor }),
        ...(dto.notes !== undefined && { notes: dto.notes }),
        ...(planTier !== undefined && { plan_tier: planTier }),
        ...(presetId !== undefined && { preset_id: presetId }),
        ...(cardId !== undefined && {
          payment_card_id: cardId,
        }),
      },
    });

    return {
      id: updated.id,
      name: updated.name,
      category: updated.category,
      price: Number(updated.price),
      planTier: updated.plan_tier,
      presetId: updated.preset_id,
      billingCycle: updated.billing_cycle,
      status: updated.status,
      nextRenewalDate: updated.next_renewal_date,
      brandColor: updated.brand_color,
      notes: updated.notes,
    };
  }

  /**
   * สร้าง Subscription ให้ผู้ใช้ (Admin action)
   */
  async createSubscription(userId: string, dto: any) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { payment_cards: true },
    });
    if (!user) {
      throw new NotFoundException(`User with ID '${userId}' not found`);
    }

    let cardId = dto.payment_card_id || dto.paymentCardId || dto.card_id;
    if (!cardId) {
      const activeCard = user.payment_cards.find((c) => c.is_active);
      if (activeCard) {
        cardId = activeCard.id;
      } else {
        const newCard = await this.prisma.paymentCard.create({
          data: {
            user_id: userId,
            card_nickname: 'Admin Virtual Card',
            card_brand: 'Visa',
            last_4_digits: '0000',
            bank_name: 'Admin System',
            is_active: true,
          },
        });
        cardId = newCard.id;
      }
    }

    const startDate = dto.start_date || dto.startDate
      ? new Date(dto.start_date || dto.startDate)
      : new Date();

    const billingCycle = (
      dto.billing_cycle ||
      dto.billingCycle ||
      'MONTHLY'
    ).toUpperCase();

    let nextRenewal = dto.next_renewal_date || dto.nextRenewalDate
      ? new Date(dto.next_renewal_date || dto.nextRenewalDate)
      : new Date(startDate);

    if (!dto.next_renewal_date && !dto.nextRenewalDate) {
      if (billingCycle === 'YEARLY') {
        nextRenewal.setFullYear(nextRenewal.getFullYear() + 1);
      } else if (billingCycle === 'WEEKLY') {
        nextRenewal.setDate(nextRenewal.getDate() + 7);
      } else {
        nextRenewal.setMonth(nextRenewal.getMonth() + 1);
      }
    }

    const planTier = dto.plan_tier !== undefined ? dto.plan_tier : dto.planTier;
    const presetId = dto.preset_id !== undefined ? dto.preset_id : dto.presetId;

    const created = await this.prisma.userSubscription.create({
      data: {
        user_id: userId,
        payment_card_id: cardId,
        preset_id: presetId || null,
        plan_tier: planTier || null,
        name: dto.name,
        category: dto.category || 'Other',
        price: dto.price !== undefined ? Number(dto.price) : 0,
        billing_cycle: billingCycle,
        start_date: startDate,
        next_renewal_date: nextRenewal,
        status: (dto.status || 'ACTIVE').toUpperCase(),
        usage_status: (
          dto.usage_status ||
          dto.usageStatus ||
          'FREQUENT'
        ).toUpperCase(),
        brand_color: dto.brand_color || dto.brandColor || '#3B82F6',
        notes: dto.notes || null,
      },
      include: {
        payment_card: {
          select: {
            id: true,
            card_nickname: true,
            card_brand: true,
            last_4_digits: true,
          },
        },
      },
    });

    return {
      id: created.id,
      name: created.name,
      category: created.category,
      price: Number(created.price),
      planTier: created.plan_tier,
      presetId: created.preset_id,
      billingCycle: created.billing_cycle,
      startDate: created.start_date,
      nextRenewalDate: created.next_renewal_date,
      status: created.status,
      usageStatus: created.usage_status,
      brandColor: created.brand_color,
      notes: created.notes,
      paymentCard: created.payment_card
        ? {
            id: created.payment_card.id,
            nickname: created.payment_card.card_nickname,
            brand: created.payment_card.card_brand,
            last4: created.payment_card.last_4_digits,
          }
        : null,
    };
  }

  /**
   * ลบ Subscription ของผู้ใช้ (Admin action)
   */
  async deleteSubscription(subId: string) {
    const existing = await this.prisma.userSubscription.findUnique({
      where: { id: subId },
    });
    if (!existing) {
      throw new NotFoundException(`Subscription with ID '${subId}' not found`);
    }

    await this.prisma.userSubscription.delete({
      where: { id: subId },
    });

    return {
      message: 'Subscription successfully removed',
      id: subId,
    };
  }

  /**
   * ลบผู้ใช้ออกจากระบบ (Admin action)
   */
  async deleteUser(id: string): Promise<{ message: string; id: string }> {
    const existing = await this.prisma.user.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundException(`User with ID '${id}' not found`);
    }

    await this.prisma.user.delete({ where: { id } });
    return {
      message: 'User successfully removed',
      id,
    };
  }
}
