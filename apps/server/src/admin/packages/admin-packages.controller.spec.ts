import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException } from '@nestjs/common';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { AdminPackagesController } from './admin-packages.controller';
import { AdminPackagesService } from './admin-packages.service';
import { UpdatePackageStatusDto } from './dto/update-package-status.dto';
import { DeletePackageQueryDto } from './dto/delete-package-query.dto';
import { AdminPackageResponseDto } from './dto/package-response.dto';

describe('AdminPackagesController (BE-305)', () => {
  let controller: AdminPackagesController;
  let service: {
    disablePackage: ReturnType<typeof vi.fn>;
    enablePackage: ReturnType<typeof vi.fn>;
    updatePackageStatus: ReturnType<typeof vi.fn>;
    deletePackage: ReturnType<typeof vi.fn>;
    createPackage: ReturnType<typeof vi.fn>;
  };

  const mockPackageResponse: AdminPackageResponseDto = {
    id: 'f10e2dbc-7668-4b6c-ad02-1b83314bb2ac',
    name: 'Netflix Standard',
    category: 'Entertainment',
    defaultPrice: 349.0,
    billingCycle: 'MONTHLY',
    brandColor: '#E50914',
    iconUrl: 'https://example.com/icons/netflix.png',
    description: '1080p Full HD video streaming',
    isActive: true,
    deletedAt: null,
    createdAt: new Date('2026-09-22T00:00:00.000Z'),
    updatedAt: new Date('2026-09-22T00:00:00.000Z'),
  };

  beforeEach(async () => {
    const mockService = {
      disablePackage: vi.fn(),
      enablePackage: vi.fn(),
      updatePackageStatus: vi.fn(),
      deletePackage: vi.fn(),
      createPackage: vi.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [AdminPackagesController],
      providers: [
        {
          provide: AdminPackagesService,
          useValue: mockService,
        },
      ],
    }).compile();

    controller = module.get<AdminPackagesController>(AdminPackagesController);
    service = module.get(AdminPackagesService);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('PATCH :id/disable', () => {
    it('should disable the package and return updated response', async () => {
      const disabledResponse: AdminPackageResponseDto = {
        ...mockPackageResponse,
        isActive: false,
        deletedAt: new Date(),
      };
      service.disablePackage.mockResolvedValue(disabledResponse);

      const result = await controller.disable('pkg-123');

      expect(service.disablePackage).toHaveBeenCalledWith('pkg-123');
      expect(result.isActive).toBe(false);
    });

    it('should throw NotFoundException if package does not exist', async () => {
      service.disablePackage.mockRejectedValue(
        new NotFoundException("Package with ID 'invalid-id' not found"),
      );

      await expect(controller.disable('invalid-id')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('PATCH :id/enable', () => {
    it('should re-enable the package and return updated response', async () => {
      service.enablePackage.mockResolvedValue(mockPackageResponse);

      const result = await controller.enable('pkg-123');

      expect(service.enablePackage).toHaveBeenCalledWith('pkg-123');
      expect(result.isActive).toBe(true);
    });
  });

  describe('PATCH :id/status', () => {
    it('should update package status with reason', async () => {
      const dto: UpdatePackageStatusDto = {
        isActive: false,
        reason: 'Temporary maintenance',
      };
      const disabledResponse: AdminPackageResponseDto = {
        ...mockPackageResponse,
        isActive: false,
      };
      service.updatePackageStatus.mockResolvedValue(disabledResponse);

      const result = await controller.updateStatus('pkg-123', dto);

      expect(service.updatePackageStatus).toHaveBeenCalledWith('pkg-123', dto);
      expect(result.isActive).toBe(false);
    });
  });

  describe('DELETE :id', () => {
    it('should soft-delete package by default (permanent: false)', async () => {
      const query: DeletePackageQueryDto = { permanent: false };
      service.deletePackage.mockResolvedValue({
        message: 'Package disabled and archived (soft-deleted)',
        id: 'pkg-123',
        permanent: false,
      });

      const result = await controller.remove('pkg-123', query);

      expect(service.deletePackage).toHaveBeenCalledWith('pkg-123', false);
      expect(result.permanent).toBe(false);
      expect(result.message).toContain('soft-deleted');
    });

    it('should permanently delete package when query permanent=true', async () => {
      const query: DeletePackageQueryDto = { permanent: true };
      service.deletePackage.mockResolvedValue({
        message: 'Package permanently deleted',
        id: 'pkg-123',
        permanent: true,
      });

      const result = await controller.remove('pkg-123', query);

      expect(service.deletePackage).toHaveBeenCalledWith('pkg-123', true);
      expect(result.permanent).toBe(true);
      expect(result.message).toContain('permanently deleted');
    });

    it('should throw NotFoundException when deleting non-existent package', async () => {
      service.deletePackage.mockRejectedValue(
        new NotFoundException("Package with ID 'invalid-id' not found"),
      );

      await expect(
        controller.remove('invalid-id', { permanent: false }),
      ).rejects.toThrow(NotFoundException);
    });
  });
});
