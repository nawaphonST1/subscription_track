import { Prisma } from '@prisma/client';
import { SubscriptionPlanDto } from '../dto/subscription-plan.dto';

/**
 * Parses the `available_plans` Json column into typed plan objects.
 * Tolerates null/malformed data (legacy rows seeded before this field
 * existed, or hand-edited DB rows) by skipping entries that don't look
 * like a plan rather than throwing.
 */
export function parseAvailablePlans(
  raw: Prisma.JsonValue | null | undefined,
): SubscriptionPlanDto[] {
  if (!Array.isArray(raw)) {
    return [];
  }

  const plans: SubscriptionPlanDto[] = [];

  for (const entry of raw) {
    if (!entry || typeof entry !== 'object' || Array.isArray(entry)) {
      continue;
    }

    const item = entry as Record<string, unknown>;
    const tier = typeof item.tier === 'string' ? item.tier : null;
    const monthlyPrice = Number(item.monthly_price ?? item.monthlyPrice);

    if (!tier || !Number.isFinite(monthlyPrice)) {
      continue;
    }

    const rawYearly = item.yearly_price ?? item.yearlyPrice;
    const yearlyPrice =
      rawYearly === null || rawYearly === undefined
        ? null
        : Number.isFinite(Number(rawYearly))
          ? Number(rawYearly)
          : null;

    const rawMaxSlots = Number(item.max_slots ?? item.maxSlots);
    const maxSlots = Number.isFinite(rawMaxSlots) && rawMaxSlots > 0 ? rawMaxSlots : 1;

    const rawFeatures = item.features;
    const features = Array.isArray(rawFeatures)
      ? rawFeatures.filter((f): f is string => typeof f === 'string')
      : [];

    plans.push({ tier, monthlyPrice, yearlyPrice, maxSlots, features });
  }

  return plans;
}
