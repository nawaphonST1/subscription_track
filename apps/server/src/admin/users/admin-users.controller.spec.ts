import { describe, it, expect, beforeEach, vi } from 'vitest';
import { AdminUsersController } from './admin-users.controller';
import { AdminUsersService } from './admin-users.service';

describe('AdminUsersController', () => {
  let controller: AdminUsersController;
  let service: AdminUsersService;

  const mockService = {
    getStats: vi.fn(),
    getUsers: vi.fn(),
    deleteUser: vi.fn(),
    getUserDetail: vi.fn(),
    updateUser: vi.fn(),
    updateSubscription: vi.fn(),
    deleteSubscription: vi.fn(),
  };

  beforeEach(() => {
    vi.clearAllMocks();
    service = mockService as unknown as AdminUsersService;
    controller = new AdminUsersController(service);
  });

  it('getStats delegates to service.getStats', async () => {
    const statsData = {
      totalUsers: 5,
      totalSubscriptions: 12,
      totalCards: 7,
      totalPackages: 10,
    };
    mockService.getStats.mockResolvedValue(statsData);

    const result = await controller.getStats();
    expect(result).toEqual(statsData);
    expect(mockService.getStats).toHaveBeenCalledTimes(1);
  });

  it('getUsers delegates to service.getUsers', async () => {
    const usersData = [
      {
        id: 'u-1',
        email: 'test@example.com',
        name: 'Tester',
        role: 'USER',
        monthlyIncome: 30000,
        subscriptionsCount: 2,
        cardsCount: 1,
        createdAt: new Date(),
      },
    ];
    mockService.getUsers.mockResolvedValue(usersData);

    const result = await controller.getUsers();
    expect(result).toEqual(usersData);
    expect(mockService.getUsers).toHaveBeenCalledTimes(1);
  });

  it('getUserDetail delegates to service.getUserDetail', async () => {
    const userDetail = {
      id: 'u-1',
      email: 'test@example.com',
      name: 'Tester',
      role: 'USER',
      monthlyIncome: 30000,
      createdAt: new Date(),
      subscriptions: [],
      paymentCards: [],
    };
    mockService.getUserDetail.mockResolvedValue(userDetail);

    const result = await controller.getUserDetail('u-1');
    expect(result).toEqual(userDetail);
    expect(mockService.getUserDetail).toHaveBeenCalledWith('u-1');
  });

  it('updateUser delegates to service.updateUser', async () => {
    const updated = { id: 'u-1', name: 'New Name' };
    mockService.updateUser.mockResolvedValue(updated);

    const result = await controller.updateUser('u-1', { name: 'New Name' });
    expect(result).toEqual(updated);
    expect(mockService.updateUser).toHaveBeenCalledWith('u-1', { name: 'New Name' });
  });

  it('updateSubscription delegates to service.updateSubscription', async () => {
    const updatedSub = { id: 'sub-1', name: 'Netflix Premium 4K' };
    mockService.updateSubscription.mockResolvedValue(updatedSub);

    const result = await controller.updateSubscription('sub-1', { name: 'Netflix Premium 4K' });
    expect(result).toEqual(updatedSub);
    expect(mockService.updateSubscription).toHaveBeenCalledWith('sub-1', { name: 'Netflix Premium 4K' });
  });

  it('deleteSubscription delegates to service.deleteSubscription', async () => {
    mockService.deleteSubscription.mockResolvedValue({ message: 'Deleted', id: 'sub-1' });

    const result = await controller.deleteSubscription('sub-1');
    expect(result).toEqual({ message: 'Deleted', id: 'sub-1' });
    expect(mockService.deleteSubscription).toHaveBeenCalledWith('sub-1');
  });

  it('deleteUser delegates to service.deleteUser', async () => {
    mockService.deleteUser.mockResolvedValue({
      message: 'User successfully removed',
      id: 'u-1',
    });

    const result = await controller.deleteUser('u-1');
    expect(result).toEqual({
      message: 'User successfully removed',
      id: 'u-1',
    });
    expect(mockService.deleteUser).toHaveBeenCalledWith('u-1');
  });
});
