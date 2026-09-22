import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { PackagesService } from './packages.service';
import { CreatePackageDto } from './dto/create-package.dto';
import { UpdatePackageDto } from './dto/update-package.dto';
import { QueryPackageDto } from './dto/query-package.dto';

@ApiTags('packages')
@ApiBearerAuth()
@Controller('packages')
export class PackagesController {
  constructor(private readonly packagesService: PackagesService) {}

  @Get()
  @ApiOperation({ summary: 'List and search preset packages catalog' })
  @ApiResponse({ status: 200, description: 'List of preset packages' })
  async findAll(@Query() query: QueryPackageDto) {
    return this.packagesService.findAll(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get details of a single preset package' })
  @ApiResponse({ status: 200, description: 'Package details' })
  @ApiResponse({ status: 404, description: 'Package not found' })
  async findOne(@Param('id') id: string) {
    return this.packagesService.findOne(id);
  }

  @Post()
  @ApiOperation({ summary: 'Admin create a new preset package' })
  @ApiResponse({ status: 201, description: 'Package created successfully' })
  @ApiResponse({ status: 409, description: 'Package name already exists' })
  async create(@Body() dto: CreatePackageDto) {
    return this.packagesService.create(dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Admin update an existing preset package' })
  @ApiResponse({ status: 200, description: 'Package updated successfully' })
  @ApiResponse({ status: 404, description: 'Package not found' })
  @ApiResponse({ status: 409, description: 'Package name already exists' })
  async update(@Param('id') id: string, @Body() dto: UpdatePackageDto) {
    return this.packagesService.update(id, dto);
  }

  @Patch(':id/disable')
  @ApiOperation({ summary: 'Admin disable a preset package (BE-305)' })
  @ApiResponse({ status: 200, description: 'Package disabled successfully' })
  @ApiResponse({ status: 404, description: 'Package not found' })
  async disable(@Param('id') id: string) {
    return this.packagesService.disable(id);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Admin delete a preset package (BE-305)' })
  @ApiResponse({ status: 200, description: 'Package deleted successfully' })
  @ApiResponse({ status: 404, description: 'Package not found' })
  async remove(@Param('id') id: string) {
    return this.packagesService.delete(id);
  }
}
