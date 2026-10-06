import * as bcrypt from 'bcryptjs';

export const DEFAULT_PIN = '111111';
export const RESET_PIN_PREFIX = '$RESET$';

/**
 * Checks whether a user's security PIN hash represents a real/custom PIN,
 * or if it is still unconfigured / default PIN ('111111') / marked as reset.
 */
export async function isPinConfigured(
  hash: string | null | undefined,
): Promise<boolean> {
  if (!hash) return false;
  if (hash === 'RESET_REQUIRED' || hash.startsWith(RESET_PIN_PREFIX)) {
    return false;
  }
  try {
    return !(await bcrypt.compare(DEFAULT_PIN, hash));
  } catch {
    return false;
  }
}
