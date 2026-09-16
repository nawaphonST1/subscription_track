import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { PaymentCardsService } from './payment-cards.service';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { CreateCardDto } from './dto/create-card.dto';
import { UpdateCardDto } from './dto/update-card.dto';
import { LinkMockCardDto } from './dto/link-mock-card.dto';

@ApiTags('cards')
@ApiBearerAuth()
@Controller('cards')
export class PaymentCardsController {
  constructor(private readonly cardsService: PaymentCardsService) {}

  @Get()
  @ApiOperation({ summary: 'List all active payment cards of current user' })
  @ApiResponse({ status: 200, description: 'List of payment cards' })
  async findAll(@CurrentUser('id') userId: string) {
    return this.cardsService.findAll(userId);
  }

  @Get('total-balance')
  @ApiOperation({
    summary: 'Calculate total spending capacity across all active cards',
  })
  @ApiResponse({
    status: 200,
    description: 'Sum of balances across active user cards',
  })
  async getTotalBalance(@CurrentUser('id') userId: string) {
    return this.cardsService.getTotalBalance(userId);
  }

  @Get('mock')
  @ApiOperation({ summary: 'List available simulated bank cards for linking' })
  @ApiResponse({
    status: 200,
    description: 'List of predefined mock bank cards',
  })
  async listMockCards() {
    return this.cardsService.listMockCards();
  }

  @Post('link')
  @ApiOperation({
    summary:
      'Auto-import simulated bank card and all its pre-attached subscriptions',
  })
  @ApiResponse({
    status: 201,
    description: 'Card linked and subscriptions auto-imported',
  })
  async linkMockCard(
    @CurrentUser('id') userId: string,
    @Body() dto: LinkMockCardDto,
  ) {
    return this.cardsService.linkMockCard(userId, dto);
  }

  @Get(':id')
  @ApiOperation({
    summary: 'Get payment card detail with attached subscriptions',
  })
  @ApiResponse({ status: 200, description: 'Card details' })
  @ApiResponse({ status: 404, description: 'Card not found' })
  async findOne(
    @CurrentUser('id') userId: string,
    @Param('id') cardId: string,
  ) {
    return this.cardsService.findOne(userId, cardId);
  }

  @Post()
  @ApiOperation({ summary: 'Add a new manual payment card' })
  @ApiResponse({ status: 201, description: 'Card created successfully' })
  async create(@CurrentUser('id') userId: string, @Body() dto: CreateCardDto) {
    return this.cardsService.create(userId, dto);
  }

  @Patch(':id')
  @ApiOperation({
    summary: 'Update payment card nickname, balance or default status',
  })
  @ApiResponse({ status: 200, description: 'Card updated' })
  @ApiResponse({ status: 404, description: 'Card not found' })
  async update(
    @CurrentUser('id') userId: string,
    @Param('id') cardId: string,
    @Body() dto: UpdateCardDto,
  ) {
    return this.cardsService.update(userId, cardId, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Deactivate a payment card' })
  @ApiResponse({ status: 200, description: 'Card deactivated' })
  @ApiResponse({ status: 404, description: 'Card not found' })
  async remove(@CurrentUser('id') userId: string, @Param('id') cardId: string) {
    return this.cardsService.remove(userId, cardId);
  }
}
