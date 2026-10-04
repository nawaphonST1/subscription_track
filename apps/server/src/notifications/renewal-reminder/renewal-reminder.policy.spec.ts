import { describe, expect, it } from 'vitest';
import {
  addUtcDays,
  buildReminderJobId,
  buildReminderWindow,
  buildRenewalDedupeKey,
  isWithinReminderWindow,
  startOfUtcDay,
  toUtcDateKey,
} from './renewal-reminder.policy';

describe('renewal-reminder.policy', () => {
  describe('startOfUtcDay', () => {
    it('truncates to midnight UTC regardless of the time-of-day component', () => {
      expect(startOfUtcDay(new Date('2026-10-05T23:59:59.999Z'))).toEqual(
        new Date('2026-10-05T00:00:00.000Z'),
      );
      expect(startOfUtcDay(new Date('2026-10-05T00:00:00.000Z'))).toEqual(
        new Date('2026-10-05T00:00:00.000Z'),
      );
    });
  });

  describe('addUtcDays', () => {
    it('adds whole calendar days across month/year boundaries', () => {
      expect(addUtcDays(new Date('2026-10-30T00:00:00.000Z'), 3)).toEqual(
        new Date('2026-11-02T00:00:00.000Z'),
      );
    });
  });

  describe('toUtcDateKey', () => {
    it('formats as YYYY-MM-DD', () => {
      expect(toUtcDateKey(new Date('2026-10-05T15:30:00.000Z'))).toBe(
        '2026-10-05',
      );
    });
  });

  describe('buildRenewalDedupeKey / buildReminderJobId', () => {
    it('produce distinct, deterministic keys for the same inputs', () => {
      const renewalDate = new Date('2026-10-08T00:00:00.000Z');
      expect(buildRenewalDedupeKey('sub-1', renewalDate)).toBe(
        'renewal-sub-1-2026-10-08',
      );
      expect(buildReminderJobId('sub-1', renewalDate)).toBe(
        'remind-sub-1-2026-10-08',
      );
    });
  });

  describe('buildReminderWindow / isWithinReminderWindow (3-day catch-up)', () => {
    const now = new Date('2026-10-05T12:00:00.000Z');

    it('builds a [today, today+4days) window', () => {
      expect(buildReminderWindow(now)).toEqual({
        start: new Date('2026-10-05T00:00:00.000Z'),
        end: new Date('2026-10-09T00:00:00.000Z'),
      });
    });

    it.each([
      ['2026-10-08', true],
      ['2026-10-07', true],
      ['2026-10-06', true],
      ['2026-10-05', true],
      ['2026-10-04', false],
      ['2026-10-09', false],
    ])('renewal on %s -> eligible=%s', (date, expected) => {
      expect(
        isWithinReminderWindow(new Date(`${date}T00:00:00.000Z`), now),
      ).toBe(expected);
    });
  });
});
