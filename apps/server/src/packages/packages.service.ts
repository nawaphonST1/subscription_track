import {
  ConflictException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CacheService } from '../cache/cache.service';
import { CreatePackageDto } from './dto/create-package.dto';
import { UpdatePackageDto } from './dto/update-package.dto';
import { QueryPackageDto } from './dto/query-package.dto';
import { SubscriptionPlanDto } from './dto/subscription-plan.dto';
import { parseAvailablePlans } from './utils/subscription-plan.util';

export interface PackageItem {
  id: string;
  name: string;
  category: string;
  default_price: number;
  billing_cycle: string;
  brand_color: string;
  icon_url: string | null;
  description: string | null;
  features: string[];
  max_slots: number;
  available_plans: SubscriptionPlanDto[];
  created_at: Date;
  updated_at: Date;
}

@Injectable()
export class PackagesService {
  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly cacheService?: CacheService,
  ) {}

  async findAll(query?: QueryPackageDto): Promise<PackageItem[]> {
    const cacheKey = `cache:packages:list:${query?.category ?? 'all'}:${query?.search ?? 'all'}`;
    if (this.cacheService) {
      const cached = await this.cacheService.get<PackageItem[]>(cacheKey);
      if (cached) {
        return cached;
      }
    }

    const where: Prisma.SubscriptionPresetWhereInput = {};

    if (query?.category) {
      where.category = {
        equals: query.category,
        mode: 'insensitive',
      };
    }

    if (query?.search) {
      where.name = {
        contains: query.search,
        mode: 'insensitive',
      };
    }

    const presets = await this.prisma.subscriptionPreset.findMany({
      where,
      orderBy: [{ category: 'asc' }, { name: 'asc' }],
    });

    const result = presets.map((p) => this.formatPackage(p));

    if (this.cacheService) {
      await this.cacheService.set(cacheKey, result, 86400);
    }

    return result;
  }

  async findOne(id: string): Promise<PackageItem> {
    const cacheKey = `cache:packages:item:${id}`;
    if (this.cacheService) {
      const cached = await this.cacheService.get<PackageItem>(cacheKey);
      if (cached) {
        return cached;
      }
    }

    const preset = await this.prisma.subscriptionPreset.findUnique({
      where: { id },
    });

    if (!preset) {
      throw new NotFoundException(`Package with ID ${id} not found`);
    }

    const result = this.formatPackage(preset);

    if (this.cacheService) {
      await this.cacheService.set(cacheKey, result, 86400);
    }

    return result;
  }

  async create(dto: CreatePackageDto) {
    const existing = await this.prisma.subscriptionPreset.findUnique({
      where: { name: dto.name },
    });

    if (existing) {
      throw new ConflictException(
        `Package with name "${dto.name}" already exists`,
      );
    }

    const created = await this.prisma.subscriptionPreset.create({
      data: {
        name: dto.name,
        category: dto.category,
        default_price: dto.default_price,
        billing_cycle: dto.billing_cycle,
        brand_color: dto.brand_color,
        icon_url: dto.icon_url,
        description: dto.description,
        ...((dto.available_plans !== undefined ||
          dto.availablePlans !== undefined) && {
          available_plans: dto.available_plans ?? dto.availablePlans,
        }),
      },
    });

    await this.evictPackageCaches();

    return this.formatPackage(created);
  }

  async update(id: string, dto: UpdatePackageDto) {
    const existing = await this.prisma.subscriptionPreset.findUnique({
      where: { id },
    });

    if (!existing) {
      throw new NotFoundException(`Package with ID ${id} not found`);
    }

    if (dto.name && dto.name !== existing.name) {
      const duplicate = await this.prisma.subscriptionPreset.findUnique({
        where: { name: dto.name },
      });

      if (duplicate) {
        throw new ConflictException(
          `Package with name "${dto.name}" already exists`,
        );
      }
    }

    const updated = await this.prisma.subscriptionPreset.update({
      where: { id },
      data: {
        ...(dto.name !== undefined && { name: dto.name }),
        ...(dto.category !== undefined && { category: dto.category }),
        ...((dto.default_price !== undefined ||
          dto.defaultPrice !== undefined) && {
          default_price: dto.default_price ?? dto.defaultPrice,
        }),
        ...((dto.billing_cycle !== undefined ||
          dto.billingCycle !== undefined) && {
          billing_cycle: dto.billing_cycle ?? dto.billingCycle,
        }),
        ...((dto.brand_color !== undefined || dto.brandColor !== undefined) && {
          brand_color: dto.brand_color ?? dto.brandColor,
        }),
        ...(dto.icon_url !== undefined && { icon_url: dto.icon_url }),
        ...(dto.description !== undefined && { description: dto.description }),
        ...((dto.available_plans !== undefined ||
          dto.availablePlans !== undefined) && {
          available_plans: dto.available_plans ?? dto.availablePlans,
        }),
      },
    });

    await this.evictPackageCaches();

    return this.formatPackage(updated);
  }

  async delete(id: string) {
    const existing = await this.prisma.subscriptionPreset.findUnique({
      where: { id },
    });

    if (!existing) {
      throw new NotFoundException(`Package with ID ${id} not found`);
    }

    await this.prisma.subscriptionPreset.delete({
      where: { id },
    });

    await this.evictPackageCaches();

    return {
      message: 'Package deleted successfully',
      id,
    };
  }

  async disable(id: string) {
    const existing = await this.prisma.subscriptionPreset.findUnique({
      where: { id },
    });

    if (!existing) {
      throw new NotFoundException(`Package with ID ${id} not found`);
    }

    await this.evictPackageCaches();

    return {
      ...this.formatPackage(existing),
      isActive: false,
    };
  }

  private async evictPackageCaches() {
    if (this.cacheService) {
      await this.cacheService.delByPattern('cache:packages:*');
      await this.cacheService.del('cache:subscriptions:presets');
    }
  }

  private formatPackage(p: {
    id: string;
    name: string;
    category: string;
    default_price: Prisma.Decimal | number;
    billing_cycle: string;
    brand_color: string;
    icon_url: string | null;
    description: string | null;
    features: string[];
    max_slots: number;
    available_plans: Prisma.JsonValue | null;
    created_at: Date;
    updated_at: Date;
  }): PackageItem {
    return {
      id: p.id,
      name: p.name,
      category: p.category,
      default_price: Number(p.default_price),
      billing_cycle: p.billing_cycle,
      brand_color: p.brand_color,
      icon_url: p.icon_url,
      description: p.description,
      features: p.features,
      max_slots: p.max_slots,
      available_plans: parseAvailablePlans(p.available_plans),
      created_at: p.created_at,
      updated_at: p.updated_at,
    };
  }
}
