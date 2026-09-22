import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { UpdatePackageStatusDto } from './dto/update-package-status.dto';
import { AdminPackageResponseDto } from './dto/package-response.dto';

@Injectable()
export class AdminPackagesService {
  /**
   * Status tracking store for soft-state while waiting for BE-303 Prisma schema migrations.
   */
  private readonly disabledPackageIds = new Set<string>();

  constructor(private readonly prisma: PrismaService) {}

  // =========================================================================
  // BE-303: Admin Create Package Placeholder
  // Reserved for teammate working on BE-303. Plug in implementation here.
  // =========================================================================
  createPackage(dto: unknown): Promise<AdminPackageResponseDto> {
    return Promise.reject(
      new Error(
        `BE-303: createPackage is being implemented in BE-303. Received: ${JSON.stringify(
          dto,
        )}`,
      ),
    );
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
