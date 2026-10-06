import { describe, it, expect } from 'vitest';
import * as bcrypt from 'bcryptjs';
import { isPinConfigured, DEFAULT_PIN } from './pin.util';

describe('isPinConfigured', () => {
  it('returns false when hash is null or undefined or empty', async () => {
    expect(await isPinConfigured(null)).toBe(false);
    expect(await isPinConfigured(undefined)).toBe(false);
    expect(await isPinConfigured('')).toBe(false);
  });

  it('returns false when hash corresponds to the default PIN 111111', async () => {
    const defaultHash = await bcrypt.hash(DEFAULT_PIN, 10);
    expect(await isPinConfigured(defaultHash)).toBe(false);
  });

  it('returns true when hash corresponds to a custom real PIN', async () => {
    const customHash = await bcrypt.hash('847291', 10);
    expect(await isPinConfigured(customHash)).toBe(true);
  });
});
