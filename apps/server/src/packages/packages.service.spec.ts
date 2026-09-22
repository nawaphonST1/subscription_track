import { describe, expect, it, vi, beforeEach } from 'vitest';
import { ConflictException, NotFoundException } from '@nestjs/common';
import { BillingCycle } from '@prisma/client';
import { PackagesService } from './packages.service';

describe('PackagesService', () => {
  let service: PackagesService;
  let prismaMock: any;

  beforeEach(() => {
    prismaMock = {
      subscriptionPreset: {
        findMany: vi.fn(),
        findUnique: vi.fn(),
        create: vi.fn(),
        update: vi.fn(),
      },
    };

    service = new PackagesService(prismaMock);
  });

  const mockPreset = {
    id: 'preset-1',
    name: 'Netflix Standard',
    category: 'Entertainment',
    default_price: 349,
    billing_cycle: BillingCycle.MONTHLY,
    brand_color: '#E50914',
    icon_url: 'https://example.com/icon.png',
    description: 'HD Streaming',
    created_at: new Date('2026-01-01'),
    updated_at: new Date('2026-01-01'),
  };

  describe('findAll (BE-302)', () => {
    it('should return all preset packages', async () => {
      prismaMock.subscriptionPreset.findMany.mockResolvedValue([mockPreset]);

      const result = await service.findAll();
      expect(result).toHaveLength(1);
      expect(result[0]).toEqual({
        id: 'preset-1',
        name: 'Netflix Standard',
        category: 'Entertainment',
        default_price: 349,
        billing_cycle: 'MONTHLY',
        brand_color: '#E50914',
        icon_url: 'https://example.com/icon.png',
        description: 'HD Streaming',
        created_at: expect.any(Date),
        updated_at: expect.any(Date),
      });
      expect(prismaMock.subscriptionPreset.findMany).toHaveBeenCalledWith({
        where: {},
        orderBy: [{ category: 'asc' }, { name: 'asc' }],
      });
    });

    it('should filter by category and search keyword', async () => {
      prismaMock.subscriptionPreset.findMany.mockResolvedValue([mockPreset]);

      const result = await service.findAll({
        category: 'Entertainment',
        search: 'Netflix',
      });
      expect(result).toHaveLength(1);
      expect(prismaMock.subscriptionPreset.findMany).toHaveBeenCalledWith({
        where: {
          category: { equals: 'Entertainment', mode: 'insensitive' },
          name: { contains: 'Netflix', mode: 'insensitive' },
        },
        orderBy: [{ category: 'asc' }, { name: 'asc' }],
      });
    });
  });

  describe('findOne (BE-302)', () => {
    it('should return package when it exists', async () => {
      prismaMock.subscriptionPreset.findUnique.mockResolvedValue(mockPreset);

      const result = await service.findOne('preset-1');
      expect(result.id).toBe('preset-1');
      expect(result.name).toBe('Netflix Standard');
    });

    it('should throw NotFoundException when package does not exist', async () => {
      prismaMock.subscriptionPreset.findUnique.mockResolvedValue(null);

      await expect(service.findOne('non-existent')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('create (BE-303)', () => {
    it('should create new preset package', async () => {
      prismaMock.subscriptionPreset.findUnique.mockResolvedValue(null);
      prismaMock.subscriptionPreset.create.mockResolvedValue(mockPreset);

      const dto = {
        name: 'Netflix Standard',
        category: 'Entertainment',
        default_price: 349,
        billing_cycle: BillingCycle.MONTHLY,
        brand_color: '#E50914',
        icon_url: 'https://example.com/icon.png',
        description: 'HD Streaming',
      };

      const result = await service.create(dto);
      expect(result.name).toBe('Netflix Standard');
      expect(prismaMock.subscriptionPreset.create).toHaveBeenCalledWith({
        data: dto,
      });
    });

    it('should throw ConflictException if package name already exists', async () => {
      prismaMock.subscriptionPreset.findUnique.mockResolvedValue(mockPreset);

      await expect(
        service.create({
          name: 'Netflix Standard',
          category: 'Entertainment',
          default_price: 349,
          brand_color: '#E50914',
        }),
      ).rejects.toThrow(ConflictException);
    });
  });

  describe('update (BE-304)', () => {
    it('should update package fields', async () => {
      prismaMock.subscriptionPreset.findUnique.mockResolvedValue(mockPreset);
      prismaMock.subscriptionPreset.update.mockResolvedValue({
        ...mockPreset,
        default_price: 399,
      });

      const result = await service.update('preset-1', { default_price: 399 });
      expect(result.default_price).toBe(399);
      expect(prismaMock.subscriptionPreset.update).toHaveBeenCalledWith({
        where: { id: 'preset-1' },
        data: expect.objectContaining({ default_price: 399 }),
      });
    });

    it('should throw NotFoundException if package does not exist', async () => {
      prismaMock.subscriptionPreset.findUnique.mockResolvedValue(null);

      await expect(
        service.update('non-existent', { default_price: 399 }),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw ConflictException if updated name conflicts with another package', async () => {
      prismaMock.subscriptionPreset.findUnique
        .mockResolvedValueOnce(mockPreset) // first call: finds existing by id
        .mockResolvedValueOnce({ id: 'preset-2', name: 'Duplicate Name' }); // second call: finds conflict

      await expect(
        service.update('preset-1', { name: 'Duplicate Name' }),
      ).rejects.toThrow(ConflictException);
    });
  });
});
