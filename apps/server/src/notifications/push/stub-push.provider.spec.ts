import { describe, expect, it, vi } from 'vitest';
import { StubPushProvider } from './stub-push.provider';

describe('StubPushProvider', () => {
  it('always reports delivered without contacting a real provider', async () => {
    const provider = new StubPushProvider();

    const result = await provider.send(
      { deviceRegistrationId: 'dev-1', token: 'secret-token' },
      {
        title: 'Upcoming renewal',
        body: 'Renews soon',
        notificationId: 'notif-1',
      },
    );

    expect(result).toEqual({ outcome: 'delivered' });
  });

  it('never logs the raw push token', async () => {
    const debugSpy = vi.spyOn(console, 'debug').mockImplementation(() => {});
    const logSpy = vi.spyOn(console, 'log').mockImplementation(() => {});
    const provider = new StubPushProvider();
    const secretToken = 'super-secret-push-token-xyz';

    await provider.send(
      { deviceRegistrationId: 'dev-1', token: secretToken },
      { title: 't', body: 'b', notificationId: 'n' },
    );

    const loggedText = [...debugSpy.mock.calls, ...logSpy.mock.calls]
      .flat()
      .map((value) => JSON.stringify(value))
      .join(' ');
    expect(loggedText).not.toContain(secretToken);

    debugSpy.mockRestore();
    logSpy.mockRestore();
  });
});
