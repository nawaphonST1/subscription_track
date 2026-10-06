import * as bcrypt from 'bcryptjs';

export const DEFAULT_PIN = '111111';

/**
 * Checks whether a user's security PIN hash represents a real/custom PIN,
 * or if it is still the initial default PIN ('111111').
 */
export async function isPinConfigured(
  hash: string | null | undefined,
): Promise<boolean> {
  if (!hash) return false;
  return !(await bcrypt.compare(DEFAULT_PIN, hash));
}
