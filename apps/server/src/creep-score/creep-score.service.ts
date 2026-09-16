import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { BillingCycle, SubscriptionStatus } from '@prisma/client';

export type RiskLevel = 'SAFE' | 'CAUTION' | 'HIGH_RISK';

@Injectable()
export class CreepScoreService {
  constructor(private readonly prisma: PrismaService) {}

  normalizeMonthlyCost(price: number, cycle: BillingCycle): number {
    switch (cycle) {
      case BillingCycle.WEEKLY:
        return (price * 52) / 12;
      case BillingCycle.YEARLY:
        return price / 12;
      case BillingCycle.MONTHLY:
      default:
        return price;
    }
  }

  determineRiskLevel(score: number): RiskLevel {
    if (score < 5.0) {
      return 'SAFE';
    } else if (score <= 15.0) {
      return 'CAUTION';
    } else {
      return 'HIGH_RISK';
    }
  }

  async getCreepScore(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { monthly_income: true },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Active subscriptions
    const activeSubscriptions = await this.prisma.userSubscription.findMany({
      where: {
        user_id: userId,
        status: SubscriptionStatus.ACTIVE,
      },
      include: {
        payment_card: {
          select: {
            card_nickname: true,
            last_4_digits: true,
          },
        },
      },
      orderBy: { next_renewal_date: 'asc' },
    });

    // Cards total balance
    const cards = await this.prisma.paymentCard.findMany({
      where: { user_id: userId, is_active: true },
      select: { balance: true },
    });

    const totalCardFunds = cards.reduce((sum, c) => sum + Number(c.balance), 0);

    // Calculate total normalized monthly expenses and category breakdown
    let totalMonthlyExpenses = 0;
    const categoryMap = new Map<string, number>();

    for (const sub of activeSubscriptions) {
      const monthly = this.normalizeMonthlyCost(
        Number(sub.price),
        sub.billing_cycle,
      );
      totalMonthlyExpenses += monthly;

      const catSum = categoryMap.get(sub.category) || 0;
      categoryMap.set(sub.category, catSum + monthly);
    }

    const monthlyIncome = Number(user.monthly_income);
    let denominator = 0;
    let denominatorUsed: 'monthly_income' | 'total_card_funds' | 'none' =
      'none';

    if (monthlyIncome > 0) {
      denominator = monthlyIncome;
      denominatorUsed = 'monthly_income';
    } else if (totalCardFunds > 0) {
      denominator = totalCardFunds;
      denominatorUsed = 'total_card_funds';
    }

    let creepScore = 0;
    if (denominator > 0) {
      creepScore = Number(
        ((totalMonthlyExpenses / denominator) * 100).toFixed(2),
      );
    } else if (totalMonthlyExpenses > 0) {
      // Expenses exist but no income or card balance set
      creepScore = 100;
    }

    const riskLevel = this.determineRiskLevel(creepScore);

    // Upcoming renewals within next 30 days
    const now = new Date();
    const in30Days = new Date(now);
    in30Days.setDate(in30Days.getDate() + 30);

    const upcomingRenewals = activeSubscriptions
      .filter(
        (s) => s.next_renewal_date >= now && s.next_renewal_date <= in30Days,
      )
      .map((s) => ({
        id: s.id,
        name: s.name,
        category: s.category,
        price: Number(s.price),
        billing_cycle: s.billing_cycle,
        next_renewal_date: s.next_renewal_date,
        days_until_renewal: Math.ceil(
          (s.next_renewal_date.getTime() - now.getTime()) /
            (1000 * 60 * 60 * 24),
        ),
        card_nickname: s.payment_card.card_nickname,
        last_4_digits: s.payment_card.last_4_digits,
      }));

    const categoryBreakdown = Array.from(categoryMap.entries()).map(
      ([category, amount]) => ({
        category,
        amount: Number(amount.toFixed(2)),
        percentage:
          totalMonthlyExpenses > 0
            ? Number(((amount / totalMonthlyExpenses) * 100).toFixed(1))
            : 0,
      }),
    );

    return {
      monthly_total: Number(totalMonthlyExpenses.toFixed(2)),
      creep_score: creepScore,
      risk_level: riskLevel,
      monthly_income: monthlyIncome,
      total_card_funds: Number(totalCardFunds.toFixed(2)),
      denominator_used: denominatorUsed,
      active_subscriptions_count: activeSubscriptions.length,
      category_breakdown: categoryBreakdown,
      upcoming_renewals: upcomingRenewals,
    };
  }
}
