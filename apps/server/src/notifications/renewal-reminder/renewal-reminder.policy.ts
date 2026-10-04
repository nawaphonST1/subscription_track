import { RENEWAL_REMINDER_DAYS_BEFORE } from './renewal-reminder.constants';

// All helpers here operate on UTC calendar days only. next_renewal_date is
// stored as a UTC timestamp and the scheduler runs at 00:00 UTC; nothing in
// this module reads the host's local timezone.

export function startOfUtcDay(now: Date): Date {
  return new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
  );
}

export function addUtcDays(date: Date, days: number): Date {
  return new Date(date.getTime() + days * 24 * 60 * 60 * 1000);
}

export function toUtcDateKey(date: Date): string {
  return date.toISOString().slice(0, 10);
}

export function buildRenewalDedupeKey(
  subscriptionId: string,
  renewalDate: Date,
): string {
  return `renewal-${subscriptionId}-${toUtcDateKey(renewalDate)}`;
}

export function buildReminderJobId(
  subscriptionId: string,
  renewalDate: Date,
): string {
  return `remind-${subscriptionId}-${toUtcDateKey(renewalDate)}`;
}

export interface ReminderWindow {
  start: Date;
  end: Date;
}

// Catch-up semantics: a renewal becomes eligible starting
// RENEWAL_REMINDER_DAYS_BEFORE days out and stays eligible through the
// renewal day itself (inclusive), so a missed scheduler run can still catch
// up. Renewals in the past (before `start`) are considered overdue and are
// intentionally excluded.
export function buildReminderWindow(now: Date): ReminderWindow {
  const start = startOfUtcDay(now);

  return {
    start,
    end: addUtcDays(start, RENEWAL_REMINDER_DAYS_BEFORE + 1),
  };
}

export function isWithinReminderWindow(renewalDate: Date, now: Date): boolean {
  const { start, end } = buildReminderWindow(now);
  return (
    renewalDate.getTime() >= start.getTime() &&
    renewalDate.getTime() < end.getTime()
  );
}
