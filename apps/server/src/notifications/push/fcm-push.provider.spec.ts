import { beforeEach, describe, expect, it, vi } from 'vitest';

const { sendMock, getMessagingMock, initializeAppMock, certMock, getAppsMock } =
  vi.hoisted(() => ({
    sendMock: vi.fn(),
    getMessagingMock: vi.fn(),
    initializeAppMock: vi.fn(() => ({ name: 'subscription-track-worker' })),
    certMock: vi.fn((credentials: unknown) => credentials),
    getAppsMock: vi.fn(() => [] as { name: string }[]),
  }));

getMessagingMock.mockImplementation(() => ({ send: sendMock }));

vi.mock('firebase-admin/app', () => ({
  cert: certMock,
  getApps: getAppsMock,
  initializeApp: initializeAppMock,
}));

vi.mock('firebase-admin/messaging', () => ({
  getMessaging: getMessagingMock,
}));

import { FcmPushProvider } from './fcm-push.provider';

const validServiceAccount = JSON.stringify({
  project_id: 'demo-project',
  client_email: 'worker@demo-project.iam.gserviceaccount.com',
  private_key: 'not-a-real-key',
});

const RAW_TOKEN = 'super-secret-push-token-must-never-be-logged';

describe('FcmPushProvider', () => {
  beforeEach(() => {
    sendMock.mockReset();
    getMessagingMock.mockClear();
    initializeAppMock.mockClear();
    certMock.mockClear();
    getAppsMock.mockReturnValue([]);
  });

  it('initializes Firebase once under a named app using the provided credentials', () => {
    new FcmPushProvider(validServiceAccount);

    expect(certMock).toHaveBeenCalledWith(JSON.parse(validServiceAccount));
    expect(initializeAppMock).toHaveBeenCalledWith(
      expect.anything(),
      'subscription-track-worker',
    );
  });

  it('reuses an already-initialized named app instead of re-initializing', () => {
    getAppsMock.mockReturnValue([{ name: 'subscription-track-worker' }]);

    new FcmPushProvider(validServiceAccount);

    expect(initializeAppMock).not.toHaveBeenCalled();
  });

  it('sends the correct token and notification payload', async () => {
    sendMock.mockResolvedValue('projects/demo/messages/1');
    const provider = new FcmPushProvider(validServiceAccount);

    const result = await provider.send(
      { deviceRegistrationId: 'dev-1', token: RAW_TOKEN },
      {
        title: 'Upcoming renewal',
        body: 'Renews soon',
        notificationId: 'notif-1',
        subscriptionId: 'sub-1',
      },
    );

    expect(result).toEqual({ outcome: 'delivered' });
    expect(sendMock).toHaveBeenCalledWith({
      token: RAW_TOKEN,
      notification: { title: 'Upcoming renewal', body: 'Renews soon' },
      data: {
        notificationId: 'notif-1',
        subscriptionId: 'sub-1',
        type: 'RENEWAL_ALERT',
      },
    });
  });

  it('omits subscriptionId from the data payload when not provided', async () => {
    sendMock.mockResolvedValue('id');
    const provider = new FcmPushProvider(validServiceAccount);

    await provider.send(
      { deviceRegistrationId: 'dev-1', token: RAW_TOKEN },
      { title: 't', body: 'b', notificationId: 'notif-1' },
    );

    expect(sendMock).toHaveBeenCalledWith(
      expect.objectContaining({
        data: { notificationId: 'notif-1', type: 'RENEWAL_ALERT' },
      }),
    );
  });

  it('classifies registration-token-not-registered as permanent_failure', async () => {
    sendMock.mockRejectedValue({
      code: 'messaging/registration-token-not-registered',
    });
    const provider = new FcmPushProvider(validServiceAccount);

    const result = await provider.send(
      { deviceRegistrationId: 'dev-1', token: RAW_TOKEN },
      { title: 't', body: 'b', notificationId: 'n' },
    );

    expect(result).toEqual({
      outcome: 'permanent_failure',
      reason: 'messaging/registration-token-not-registered',
    });
  });

  it('classifies invalid-registration-token as permanent_failure', async () => {
    sendMock.mockRejectedValue({
      code: 'messaging/invalid-registration-token',
    });
    const provider = new FcmPushProvider(validServiceAccount);

    const result = await provider.send(
      { deviceRegistrationId: 'dev-1', token: RAW_TOKEN },
      { title: 't', body: 'b', notificationId: 'n' },
    );

    expect(result.outcome).toBe('permanent_failure');
  });

  it('classifies server-unavailable as transient_failure', async () => {
    sendMock.mockRejectedValue({ code: 'messaging/server-unavailable' });
    const provider = new FcmPushProvider(validServiceAccount);

    const result = await provider.send(
      { deviceRegistrationId: 'dev-1', token: RAW_TOKEN },
      { title: 't', body: 'b', notificationId: 'n' },
    );

    expect(result).toEqual({
      outcome: 'transient_failure',
      reason: 'messaging/server-unavailable',
    });
  });

  it('does not classify invalid-argument as a permanent token failure, and rethrows instead', async () => {
    const error = {
      code: 'messaging/invalid-argument',
      message: 'bad payload',
    };
    sendMock.mockRejectedValue(error);
    const provider = new FcmPushProvider(validServiceAccount);

    await expect(
      provider.send(
        { deviceRegistrationId: 'dev-1', token: RAW_TOKEN },
        { title: 't', body: 'b', notificationId: 'n' },
      ),
    ).rejects.toBe(error);
  });

  it('rethrows unrecognized error codes instead of guessing a classification', async () => {
    const error = { code: 'messaging/some-unmapped-future-code' };
    sendMock.mockRejectedValue(error);
    const provider = new FcmPushProvider(validServiceAccount);

    await expect(
      provider.send(
        { deviceRegistrationId: 'dev-1', token: RAW_TOKEN },
        { title: 't', body: 'b', notificationId: 'n' },
      ),
    ).rejects.toBe(error);
  });

  it('never logs the raw push token on success or failure', async () => {
    const consoleSpies = ['log', 'warn', 'error', 'debug'].map((method) =>
      vi.spyOn(console, method as 'log').mockImplementation(() => {}),
    );

    sendMock.mockResolvedValueOnce('ok');
    const provider = new FcmPushProvider(validServiceAccount);
    await provider.send(
      { deviceRegistrationId: 'dev-1', token: RAW_TOKEN },
      { title: 't', body: 'b', notificationId: 'n' },
    );

    sendMock.mockRejectedValueOnce({ code: 'messaging/server-unavailable' });
    await provider.send(
      { deviceRegistrationId: 'dev-1', token: RAW_TOKEN },
      { title: 't', body: 'b', notificationId: 'n' },
    );

    const loggedText = consoleSpies
      .flatMap((spy) => spy.mock.calls)
      .flat()
      .map((value) => JSON.stringify(value))
      .join(' ');

    expect(loggedText).not.toContain(RAW_TOKEN);

    consoleSpies.forEach((spy) => spy.mockRestore());
  });
});
