import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { PackagesService } from '../../packages/packages.service';
import { CreatePackageDto } from '../../packages/dto/create-package.dto';
import { UpdatePackageDto } from '../../packages/dto/update-package.dto';
import { UpdatePackageStatusDto } from './dto/update-package-status.dto';
import { AdminPackageResponseDto } from './dto/package-response.dto';

@Injectable()
export class AdminPackagesService {
  /**
   * Status tracking store for soft-state while waiting for BE-303 Prisma schema migrations.
   */
  private readonly disabledPackageIds = new Set<string>();

  constructor(
    private readonly prisma: PrismaService,
    private readonly packagesService: PackagesService,
  ) {}

  /**
   * Get all preset packages for admin catalog management.
   */
  async getAllPackages(): Promise<AdminPackageResponseDto[]> {
    const presets = await this.prisma.subscriptionPreset.findMany({
      orderBy: { name: 'asc' },
    });
    return presets.map((p) =>
      this.mapToResponse(p, !this.disabledPackageIds.has(p.id)),
    );
  }

  // =========================================================================
  // BE-303: Admin Create Package Implementation
  // Connected directly to PackagesService (BE-303)
  // =========================================================================
  async createPackage(dto: CreatePackageDto): Promise<AdminPackageResponseDto> {
    const created = await this.packagesService.create(dto);
    return {
      id: created.id,
      name: created.name,
      category: created.category,
      defaultPrice: created.default_price,
      billingCycle: created.billing_cycle,
      brandColor: created.brand_color,
      iconUrl: created.icon_url,
      description: created.description,
      isActive: true,
      deletedAt: null,
      createdAt: created.created_at,
      updatedAt: created.updated_at,
    };
  }

  /**
   * Admin update an existing preset package.
   */
  async updatePackage(
    id: string,
    dto: UpdatePackageDto,
  ): Promise<AdminPackageResponseDto> {
    const updated = await this.packagesService.update(id, dto);
    const isActive = !this.disabledPackageIds.has(updated.id);
    return {
      id: updated.id,
      name: updated.name,
      category: updated.category,
      defaultPrice: updated.default_price,
      billingCycle: updated.billing_cycle,
      brandColor: updated.brand_color,
      iconUrl: updated.icon_url,
      description: updated.description,
      isActive,
      deletedAt: isActive ? null : new Date(),
      createdAt: updated.created_at,
      updatedAt: updated.updated_at,
    };
  }


  // =========================================================================
  // BE-305: Admin Disable / Delete Package Implementations
  // =========================================================================

  /**
   * Disable a package so that it cannot be selected by mobile users.
   */
  async disablePackage(id: string): Promise<AdminPackageResponseDto> {
    return this.updatePackageStatus(id, { isActive: false });
  }

  /**
   * Re-enable a previously disabled package.
   */
  async enablePackage(id: string): Promise<AdminPackageResponseDto> {
    return this.updatePackageStatus(id, { isActive: true });
  }

  /**
   * Update active status of a package with optional reason.
   */
  async updatePackageStatus(
    id: string,
    dto: UpdatePackageStatusDto,
  ): Promise<AdminPackageResponseDto> {
    const preset = await this.prisma.subscriptionPreset.findUnique({
      where: { id },
    });

    if (!preset) {
      throw new NotFoundException(`Package with ID '${id}' not found`);
    }

    if (dto.isActive) {
      this.disabledPackageIds.delete(id);
    } else {
      this.disabledPackageIds.add(id);
    }

    return this.mapToResponse(preset, dto.isActive);
  }

  /**
   * Delete or soft-delete a package.
   */
  async deletePackage(
    id: string,
    permanent = false,
  ): Promise<{ message: string; id: string; permanent: boolean }> {
    const preset = await this.prisma.subscriptionPreset.findUnique({
      where: { id },
    });

    if (!preset) {
      throw new NotFoundException(`Package with ID '${id}' not found`);
    }

    if (permanent) {
      // Hard delete from database
      await this.prisma.subscriptionPreset.delete({
        where: { id },
      });
      this.disabledPackageIds.delete(id);

      return {
        message: 'Package permanently deleted',
        id,
        permanent: true,
      };
    }

    // Soft delete: disable package
    this.disabledPackageIds.add(id);

    return {
      message: 'Package disabled and archived (soft-deleted)',
      id,
      permanent: false,
    };
  }

  /**
   * Map database model to AdminPackageResponseDto
   */
  private mapToResponse(
    preset: {
      id: string;
      name: string;
      category: string;
      default_price: { toNumber(): number } | number;
      billing_cycle: string;
      brand_color: string;
      icon_url: string | null;
      description: string | null;
      created_at: Date;
      updated_at: Date;
    },
    forcedActive?: boolean,
  ): AdminPackageResponseDto {
    const isActive =
      forcedActive !== undefined
        ? forcedActive
        : !this.disabledPackageIds.has(preset.id);

    return {
      id: preset.id,
      name: preset.name,
      category: preset.category,
      defaultPrice:
        typeof preset.default_price === 'number'
          ? preset.default_price
          : preset.default_price.toNumber(),
      billingCycle: preset.billing_cycle,
      brandColor: preset.brand_color,
      iconUrl: preset.icon_url,
      description: preset.description,
      isActive,
      deletedAt: isActive ? null : new Date(),
      createdAt: preset.created_at,
      updatedAt: preset.updated_at,
    };
  }
}
