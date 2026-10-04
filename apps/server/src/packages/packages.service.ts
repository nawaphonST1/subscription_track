import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePackageDto } from './dto/create-package.dto';
import { UpdatePackageDto } from './dto/update-package.dto';
import { QueryPackageDto } from './dto/query-package.dto';

@Injectable()
export class PackagesService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(query?: QueryPackageDto) {
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

    return presets.map((p) => this.formatPackage(p));
  }

  async findOne(id: string) {
    const preset = await this.prisma.subscriptionPreset.findUnique({
      where: { id },
    });

    if (!preset) {
      throw new NotFoundException(`Package with ID ${id} not found`);
    }

    return this.formatPackage(preset);
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
      },
    });

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
        name: dto.name,
        category: dto.category,
        default_price: dto.default_price,
        billing_cycle: dto.billing_cycle,
        brand_color: dto.brand_color,
        icon_url: dto.icon_url,
        description: dto.description,
      },
    });

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

    return {
      ...this.formatPackage(existing),
      isActive: false,
    };
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
    created_at: Date;
    updated_at: Date;
  }) {
    return {
      id: p.id,
      name: p.name,
      category: p.category,
      default_price: Number(p.default_price),
      billing_cycle: p.billing_cycle,
      brand_color: p.brand_color,
      icon_url: p.icon_url,
      description: p.description,
      created_at: p.created_at,
      updated_at: p.updated_at,
    };
  }
}
