import { describe, expect, it } from 'vitest';

import {
  REDACTED,
  isSensitiveKey,
  passesLuhn,
  scrubEvent,
  scrubString,
  scrubValue,
} from './sentry.scrub';

describe('Sentry scrubbing', () => {
  it('1. redacts credential-shaped keys however deeply they are nested', () => {
    const scrubbed = scrubValue({
      body: {
        email: 'user@example.com',
        password: 'hunter2',
        profile: { pin: '1234', nested: { refreshToken: 'abc' } },
      },
    }) as Record<string, Record<string, unknown>>;

    expect(scrubbed.body.password).toBe(REDACTED);
    expect((scrubbed.body.profile as Record<string, unknown>).pin).toBe(
      REDACTED,
    );
    expect(
      (scrubbed.body.profile as Record<string, Record<string, unknown>>).nested
        .refreshToken,
    ).toBe(REDACTED);
  });

  it('2. does not redact keys that merely contain a sensitive word', () => {
    expect(isSensitiveKey('author')).toBe(false);
    expect(isSensitiveKey('passengerCount')).toBe(false);
    expect(isSensitiveKey('spinner')).toBe(false);
    expect(isSensitiveKey('password')).toBe(true);
    expect(isSensitiveKey('API_KEY')).toBe(true);
    expect(isSensitiveKey('authorization')).toBe(true);
  });

  // Regression for a real finding: the original /^.*\bpin\b.*$/i pattern
  // never matches `current_pin` or `currentPin`, because `\b` does not fire
  // across an underscore (both sides are \w) and camelCase has no delimiter
  // at all for \b to find. These are not hypothetical names — they are the
  // actual field/variable names this codebase uses today for PIN values:
  //   apps/server/src/users/dto/change-pin.dto.ts:9,15   (current_pin, new_pin)
  //   apps/server/src/users/users.service.ts:143,153,158,164 (currentPin, newPin)
  //   apps/server/src/savings/dto/batch-cancel.dto.ts:29  (security_pin)
  //   apps/server/src/auth/auth.service.ts:36,45          (security_pin, securityPinHash)
  //   apps/server/src/savings/savings.service.ts:97       (security_pin)
  // Before the fix, every one of these was `isSensitiveKey(...) === false`,
  // meaning a PIN under any of these real keys reached Sentry in plaintext.
  it('2b. redacts every real PIN field/variable name used in this codebase', () => {
    expect(isSensitiveKey('current_pin')).toBe(true);
    expect(isSensitiveKey('new_pin')).toBe(true);
    expect(isSensitiveKey('security_pin')).toBe(true);
    expect(isSensitiveKey('currentPin')).toBe(true);
    expect(isSensitiveKey('newPin')).toBe(true);
    expect(isSensitiveKey('securityPinHash')).toBe(true);
    expect(isSensitiveKey('security_pin_hash')).toBe(true);
    expect(isSensitiveKey('pin')).toBe(true);
  });

  // Regression for a bug introduced, and caught, while fixing 2b: a naive
  // broadening of the pin check to a plain substring match
  // (normalizeKey(key).includes('pin')) passed every case in 2b but also
  // redacted "mapping", "dropping" and "bookkeeping" — every English word
  // ending "-pping"/"-ping" contains the letters p-i-n. That is not a short,
  // enumerable exception list (shipping, stopping, hopping, wrapping,
  // clipping, shopping, cropping, dripping, gripping, popping, propping,
  // skipping, slipping, snipping, stripping, tripping, whipping, zipping,
  // ...), so it is fixed at the source: "pin" is matched as a whole word via
  // toWords(), not a substring.
  it('2c. does not redact ordinary words that merely contain the letters "pin"', () => {
    for (const word of [
      'bookkeeping',
      'mapping',
      'dropping',
      'shipping',
      'stopping',
      'wrapping',
      'clipping',
      'shopping',
      'cropping',
      'gripping',
      'skipping',
      'pinpoint',
      'pinned',
      'unpin',
      'spin',
    ]) {
      expect(isSensitiveKey(word)).toBe(false);
    }
  });

  it('2d. redacts a real ChangePinDto-shaped payload end to end', () => {
    // Mirrors apps/server/src/users/dto/change-pin.dto.ts exactly.
    const scrubbed = scrubValue({
      extra: { current_pin: '111111', new_pin: '222222' },
    }) as { extra: { current_pin: unknown; new_pin: unknown } };

    expect(scrubbed.extra.current_pin).toBe(REDACTED);
    expect(scrubbed.extra.new_pin).toBe(REDACTED);
  });

  it('2e. redacts unboundaried PIN compounds without regressing on false-positives (F2-NEW-2)', () => {
    // Unboundaried compounds (F2-NEW-2)
    expect(isSensitiveKey('pincode')).toBe(true);
    expect(isSensitiveKey('pin1')).toBe(true);
    expect(isSensitiveKey('pin2')).toBe(true);
    expect(isSensitiveKey('pin3')).toBe(true);
    expect(isSensitiveKey('oldpincode')).toBe(true);
    expect(isSensitiveKey('newpincode')).toBe(true);
    expect(isSensitiveKey('confirmpin')).toBe(true);
    expect(isSensitiveKey('userpin')).toBe(true);

    // False positives protection (-pping / -ping words must stay unredacted)
    expect(isSensitiveKey('mapping')).toBe(false);
    expect(isSensitiveKey('dropping')).toBe(false);
    expect(isSensitiveKey('shipping')).toBe(false);

    // Real field names in this codebase
    expect(isSensitiveKey('current_pin')).toBe(true);
    expect(isSensitiveKey('new_pin')).toBe(true);
    expect(isSensitiveKey('security_pin')).toBe(true);
    expect(isSensitiveKey('currentPin')).toBe(true);
    expect(isSensitiveKey('newPin')).toBe(true);
    expect(isSensitiveKey('securityPinHash')).toBe(true);
    expect(isSensitiveKey('security_pin_hash')).toBe(true);
    expect(isSensitiveKey('isPinValid')).toBe(true);

    // Standard acronym forms
    expect(isSensitiveKey('verifyPIN')).toBe(true);
    expect(isSensitiveKey('oldPIN')).toBe(true);
    expect(isSensitiveKey('newPIN')).toBe(true);
  });

  it('3. redacts a JWT anywhere in a free-text string', () => {
    const jwt =
      'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dBjftJeZ4CVPmB92K27uhbUJU1p1r_wW1gFWFOEjXk';
    expect(scrubString(`token rejected: ${jwt}`)).toBe(
      'token rejected: [redacted-jwt]',
    );
  });

  it('4. redacts Authorization-header values while keeping the scheme', () => {
    expect(scrubString('Authorization: Bearer abcdef0123456789')).toBe(
      `Authorization: Bearer ${REDACTED}`,
    );
  });

  it('5. redacts card-like numbers only when they pass Luhn', () => {
    expect(passesLuhn('4242424242424242')).toBe(true);
    expect(scrubString('card 4242 4242 4242 4242 declined')).toBe(
      'card [redacted-card] declined',
    );
    // A 16-digit number that is not a card — an id, a timestamp run — survives.
    expect(passesLuhn('1234567890123456')).toBe(false);
    expect(scrubString('order 1234567890123456')).toBe(
      'order 1234567890123456',
    );
  });

  it('5b. does not eat the surrounding words when redacting', () => {
    // Both of these were bugs caught by the first run of this suite: a `Token`
    // scheme pattern redacted the word after "token", and the card pattern
    // consumed the space after the number.
    expect(scrubString('token rejected for order 4242424242424242 today')).toBe(
      'token rejected for order [redacted-card] today',
    );
  });

  it('6. redacts e-mail addresses', () => {
    expect(scrubString('no account for alice.b+tag@example.co.th')).toBe(
      'no account for [redacted-email]',
    );
  });

  it('7. survives a self-referential object instead of hanging', () => {
    const cyclic: Record<string, unknown> = { name: 'req' };
    cyclic.self = cyclic;

    const scrubbed = scrubValue(cyclic) as Record<string, unknown>;

    expect(scrubbed.name).toBe('req');
    expect(scrubbed.self).toBe('[circular]');
  });

  it('8. truncates rather than recursing without bound', () => {
    let deep: Record<string, unknown> = { leaf: 'value' };
    for (let index = 0; index < 20; index += 1) {
      deep = { level: deep };
    }

    expect(JSON.stringify(scrubValue(deep))).toContain('[truncated]');
  });

  it('9. strips request headers, cookies and the query string', () => {
    const scrubbed = scrubEvent({
      request: {
        url: 'https://example.com/subscriptions?token=abc123xyz',
        query_string: 'token=abc123xyz',
        headers: {
          authorization: 'Bearer abcdef0123456789',
          'user-agent': 'k6',
        },
        cookies: { session: 'abc' },
      },
    });

    expect(scrubbed.request?.headers).toBeUndefined();
    expect(scrubbed.request?.cookies).toBeUndefined();
    expect(scrubbed.request?.query_string).toBeUndefined();
    expect(scrubbed.request?.url).toBe('https://example.com/subscriptions');
  });

  it('10. reduces the user to an internal id and nothing else', () => {
    const scrubbed = scrubEvent({
      user: {
        id: 42,
        email: 'u@example.com',
        username: 'u',
        ip_address: '203.0.113.10',
      },
    });

    expect(scrubbed.user).toEqual({ id: '42' });
  });

  it('11. leaves an event with no user and no request untouched in shape', () => {
    const scrubbed = scrubEvent({
      message: 'queue drained',
      tags: { service: 'worker' },
    });

    expect(scrubbed.message).toBe('queue drained');
    expect(scrubbed.tags).toEqual({ service: 'worker' });
  });
});
