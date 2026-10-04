import {
  Body,
  Controller,
  Delete,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiQuery,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { AdminPackagesService } from './admin-packages.service';
import { CreatePackageDto } from '../../packages/dto/create-package.dto';
import { UpdatePackageStatusDto } from './dto/update-package-status.dto';
import { DeletePackageQueryDto } from './dto/delete-package-query.dto';
import { AdminPackageResponseDto } from './dto/package-response.dto';

@ApiTags('admin-packages')
@ApiBearerAuth()
@Controller('admin/packages')
export class AdminPackagesController {
  constructor(private readonly adminPackagesService: AdminPackagesService) {}

  // =========================================================================
  // BE-303: Admin Create Package (Connected with BE-303)
  // =========================================================================
  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Admin create a new preset package (BE-303)',
    description: 'Creates a new package preset in the catalog.',
  })
  @ApiResponse({
    status: 201,
    description: 'Package successfully created',
    type: AdminPackageResponseDto,
  })
  @ApiResponse({ status: 409, description: 'Package name already exists' })
  async create(
    @Body() dto: CreatePackageDto,
  ): Promise<AdminPackageResponseDto> {
    return this.adminPackagesService.createPackage(dto);
  }

  // =========================================================================
  // BE-305: Admin Disable / Delete Package Endpoints
  // =========================================================================

  @Patch(':id/disable')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Disable a package (BE-305)',
    description:
      'Disables an active package preset so it is no longer selectable in the mobile catalog.',
  })
  @ApiParam({
    name: 'id',
    description: 'Unique UUID of the package to disable',
    example: 'f10e2dbc-7668-4b6c-ad02-1b83314bb2ac',
  })
  @ApiResponse({
    status: 200,
    description: 'Package successfully disabled',
    type: AdminPackageResponseDto,
  })
  @ApiResponse({ status: 404, description: 'Package not found' })
  async disable(@Param('id') id: string): Promise<AdminPackageResponseDto> {
    return this.adminPackagesService.disablePackage(id);
  }

  @Patch(':id/enable')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Re-enable a package',
    description: 'Re-enables a previously disabled package preset.',
  })
  @ApiParam({
    name: 'id',
    description: 'Unique UUID of the package to enable',
    example: 'f10e2dbc-7668-4b6c-ad02-1b83314bb2ac',
  })
  @ApiResponse({
    status: 200,
    description: 'Package successfully re-enabled',
    type: AdminPackageResponseDto,
  })
  @ApiResponse({ status: 404, description: 'Package not found' })
  async enable(@Param('id') id: string): Promise<AdminPackageResponseDto> {
    return this.adminPackagesService.enablePackage(id);
  }

  @Patch(':id/status')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Update package active status and reason (BE-305)',
    description:
      'Dynamically update package active state with optional maintenance/deactivation reason.',
  })
  @ApiParam({
    name: 'id',
    description: 'Unique UUID of the package',
    example: 'f10e2dbc-7668-4b6c-ad02-1b83314bb2ac',
  })
  @ApiResponse({
    status: 200,
    description: 'Package status successfully updated',
    type: AdminPackageResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Invalid request payload' })
  @ApiResponse({ status: 404, description: 'Package not found' })
  async updateStatus(
    @Param('id') id: string,
    @Body() dto: UpdatePackageStatusDto,
  ): Promise<AdminPackageResponseDto> {
    return this.adminPackagesService.updatePackageStatus(id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Delete or soft-delete a package (BE-305)',
    description:
      'Archives/soft-deletes a package preset by default. Pass ?permanent=true for permanent database removal.',
  })
  @ApiParam({
    name: 'id',
    description: 'Unique UUID of the package to delete',
    example: 'f10e2dbc-7668-4b6c-ad02-1b83314bb2ac',
  })
  @ApiQuery({
    name: 'permanent',
    required: false,
    type: Boolean,
    description:
      'When true, permanently deletes the row from the database. Default is false (soft delete).',
  })
  @ApiResponse({
    status: 200,
    description: 'Package deleted or soft-deleted successfully',
  })
  @ApiResponse({ status: 404, description: 'Package not found' })
  async remove(
    @Param('id') id: string,
    @Query() query: DeletePackageQueryDto,
  ): Promise<{ message: string; id: string; permanent: boolean }> {
    return this.adminPackagesService.deletePackage(id, query.permanent);
  }
}
