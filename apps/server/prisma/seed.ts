import { PrismaClient, CardType, BillingCycle } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database with Subscription Presets and Mock Bank Cards...');

  // 1. Subscription Presets Catalog
  // `default_price`/`billing_cycle` always mirror one entry of `available_plans`
  // (the service's existing default tier) so denormalized UserSubscription rows,
  // dashboard and savings readers keep working unchanged for callers that don't
  // yet understand multi-tier plans.
  const presets = [
    {
      name: 'Netflix Premium',
      category: 'Streaming',
      default_price: 419.0,
      billing_cycle: BillingCycle.MONTHLY,
      brand_color: '#E50914',
      icon_url: 'https://assets.nflxext.com/ffe/siteui/common/icons/nficon2016.ico',
      description: 'Ultra HD 4K streaming, 4 simultaneous screens, download on 6 devices.',
      max_slots: 4,
      features: ['4K UHD + HDR', '4 Screens', 'Spatial Audio', 'Download on 6 devices'],
      available_plans: [
        { tier: 'Mobile', monthly_price: 99.0, yearly_price: 990.0, max_slots: 1, features: ['480p SD', '1 Phone/Tablet'] },
        { tier: 'Standard', monthly_price: 349.0, yearly_price: 3490.0, max_slots: 2, features: ['1080p Full HD', '2 Screens simultaneously'] },
        { tier: 'Premium', monthly_price: 419.0, yearly_price: 4190.0, max_slots: 4, features: ['4K UHD + HDR', '4 Screens', 'Spatial Audio', 'Download on 6 devices'] },
      ],
    },
    {
      name: 'Spotify Premium',
      category: 'Music',
      default_price: 139.0,
      billing_cycle: BillingCycle.MONTHLY,
      brand_color: '#1DB954',
      icon_url: 'https://open.spotifycdn.com/cdn/images/favicon.0f31d2ea.ico',
      description: 'Ad-free music listening, offline playback, on-demand playback.',
      max_slots: 6,
      features: ['Ad-free music', 'Offline playback', 'Individual account'],
      available_plans: [
        { tier: 'Individual', monthly_price: 139.0, yearly_price: 1390.0, max_slots: 1, features: ['Ad-free music', 'Offline playback', 'Individual account'] },
        { tier: 'Duo', monthly_price: 189.0, yearly_price: 1890.0, max_slots: 2, features: ['2 Premium accounts for couples', 'Ad-free'] },
        { tier: 'Family', monthly_price: 219.0, yearly_price: 2190.0, max_slots: 6, features: ['Up to 6 Premium accounts', 'Spotify Kids', 'Explicit content filter'] },
      ],
    },
    {
      name: 'YouTube Premium',
      category: 'Streaming',
      default_price: 179.0,
      billing_cycle: BillingCycle.MONTHLY,
      brand_color: '#FF0000',
      icon_url: 'https://www.youtube.com/s/desktop/9b48c66e/img/favicon.ico',
      description: 'Ad-free videos, background playback, and YouTube Music Premium.',
      max_slots: 5,
      features: ['Ad-free videos', 'Background playback', 'YouTube Music Premium'],
      available_plans: [
        { tier: 'Individual', monthly_price: 179.0, yearly_price: 1790.0, max_slots: 1, features: ['Ad-free videos', 'Background playback', 'YouTube Music Premium'] },
        { tier: 'Family', monthly_price: 339.0, yearly_price: 3390.0, max_slots: 5, features: ['Up to 5 family members (13+)', 'Background play', 'YouTube Music included'] },
      ],
    },
    {
      name: 'ChatGPT Plus',
      category: 'Productivity',
      default_price: 720.0,
      billing_cycle: BillingCycle.MONTHLY,
      brand_color: '#10A37F',
      icon_url: 'https://oaistatic-cdn.azureedge.net/favicon.ico',
      description: 'Access to GPT-4o, canvas, image generation, web browsing, advanced voice.',
      max_slots: 1,
      features: ['GPT-4o access', 'Canvas & image generation', 'Web browsing', 'Advanced voice'],
      available_plans: [
        { tier: 'Plus', monthly_price: 720.0, yearly_price: null, max_slots: 1, features: ['GPT-4o access', 'Canvas & image generation', 'Web browsing', 'Advanced voice'] },
      ],
    },
    {
      name: 'Disney+ Hotstar',
      category: 'Streaming',
      default_price: 289.0,
      billing_cycle: BillingCycle.MONTHLY,
      brand_color: '#113CCF',
      icon_url: 'https://www.hotstar.com/favicon.ico',
      description: 'Blockbusters from Disney, Pixar, Marvel, Star Wars, and National Geographic.',
      max_slots: 1,
      features: ['Disney, Pixar, Marvel, Star Wars & Nat Geo', 'Full HD streaming'],
      available_plans: [
        { tier: 'Standard', monthly_price: 289.0, yearly_price: 2890.0, max_slots: 1, features: ['Disney, Pixar, Marvel, Star Wars & Nat Geo', 'Full HD streaming'] },
      ],
    },
    {
      name: 'Apple One',
      category: 'Entertainment',
      default_price: 379.0,
      billing_cycle: BillingCycle.MONTHLY,
      brand_color: '#000000',
      icon_url: 'https://www.apple.com/favicon.ico',
      description: 'Apple Music, Apple TV+, Apple Arcade, and 50GB iCloud storage bundle.',
      max_slots: 1,
      features: ['Apple Music', 'Apple TV+', 'Apple Arcade', '50GB iCloud storage'],
      available_plans: [
        { tier: 'Individual', monthly_price: 379.0, yearly_price: null, max_slots: 1, features: ['Apple Music', 'Apple TV+', 'Apple Arcade', '50GB iCloud storage'] },
      ],
    },
    {
      name: 'iCloud+ 200GB',
      category: 'Cloud',
      default_price: 99.0,
      billing_cycle: BillingCycle.MONTHLY,
      brand_color: '#3399FF',
      icon_url: 'https://www.icloud.com/favicon.ico',
      description: '200GB cloud storage, Private Relay, Hide My Email, custom email domain.',
      max_slots: 1,
      features: ['200GB cloud storage', 'Private Relay', 'Hide My Email', 'Custom email domain'],
      available_plans: [
        { tier: '200GB', monthly_price: 99.0, yearly_price: null, max_slots: 1, features: ['200GB cloud storage', 'Private Relay', 'Hide My Email', 'Custom email domain'] },
      ],
    },
    {
      name: 'GitHub Copilot',
      category: 'Development',
      default_price: 350.0,
      billing_cycle: BillingCycle.MONTHLY,
      brand_color: '#24292E',
      icon_url: 'https://github.githubassets.com/favicons/favicon.png',
      description: 'AI pair programmer providing code completions and chat in your IDE.',
      max_slots: 1,
      features: ['AI code completions', 'In-IDE chat'],
      available_plans: [
        { tier: 'Individual', monthly_price: 350.0, yearly_price: null, max_slots: 1, features: ['AI code completions', 'In-IDE chat'] },
      ],
    },
  ];

  for (const preset of presets) {
    await prisma.subscriptionPreset.upsert({
      where: { name: preset.name },
      update: preset,
      create: preset,
    });
  }
  console.log(`Upserted ${presets.length} subscription presets.`);

  // 2. Mock Bank Cards & Pre-populated active services
  const mockCards = [
    {
      card_nickname: 'KBank Platinum Debit',
      card_brand: 'Visa',
      card_type: CardType.DEBIT,
      last_4_digits: '9999',
      bank_name: 'Kasikornbank',
      balance: 15000.0,
      currency: 'THB',
      subscriptions: [
        {
          name: 'Netflix Premium',
          category: 'Streaming',
          price: 419.0,
          billing_cycle: BillingCycle.MONTHLY,
          brand_color: '#E50914',
        },
        {
          name: 'Spotify Premium',
          category: 'Music',
          price: 139.0,
          billing_cycle: BillingCycle.MONTHLY,
          brand_color: '#1DB954',
        },
        {
          name: 'ChatGPT Plus',
          category: 'Productivity',
          price: 720.0,
          billing_cycle: BillingCycle.MONTHLY,
          brand_color: '#10A37F',
        },
      ],
    },
    {
      card_nickname: 'SCB Ultra Platinum',
      card_brand: 'Mastercard',
      card_type: CardType.CREDIT,
      last_4_digits: '8888',
      bank_name: 'Siam Commercial Bank',
      balance: 45000.0,
      currency: 'THB',
      subscriptions: [
        {
          name: 'Disney+ Hotstar',
          category: 'Streaming',
          price: 289.0,
          billing_cycle: BillingCycle.MONTHLY,
          brand_color: '#113CCF',
        },
        {
          name: 'Apple One',
          category: 'Entertainment',
          price: 379.0,
          billing_cycle: BillingCycle.MONTHLY,
          brand_color: '#000000',
        },
        {
          name: 'GitHub Copilot',
          category: 'Development',
          price: 350.0,
          billing_cycle: BillingCycle.MONTHLY,
          brand_color: '#24292E',
        },
      ],
    },
    {
      card_nickname: 'BBL Be1st Smart',
      card_brand: 'Mastercard',
      card_type: CardType.DEBIT,
      last_4_digits: '7777',
      bank_name: 'Bangkok Bank',
      balance: 8500.0,
      currency: 'THB',
      subscriptions: [
        {
          name: 'YouTube Premium',
          category: 'Streaming',
          price: 179.0,
          billing_cycle: BillingCycle.MONTHLY,
          brand_color: '#FF0000',
        },
        {
          name: 'iCloud+ 200GB',
          category: 'Cloud',
          price: 99.0,
          billing_cycle: BillingCycle.MONTHLY,
          brand_color: '#3399FF',
        },
      ],
    },
  ];

  for (const cardData of mockCards) {
    const existing = await prisma.mockBankCard.findFirst({
      where: {
        bank_name: cardData.bank_name,
        last_4_digits: cardData.last_4_digits,
      },
      include: { subscriptions: true },
    });

    if (existing) {
      // Update balance and nickname
      await prisma.mockBankCard.update({
        where: { id: existing.id },
        data: {
          card_nickname: cardData.card_nickname,
          card_brand: cardData.card_brand,
          card_type: cardData.card_type,
          balance: cardData.balance,
          currency: cardData.currency,
        },
      });
    } else {
      await prisma.mockBankCard.create({
        data: {
          card_nickname: cardData.card_nickname,
          card_brand: cardData.card_brand,
          card_type: cardData.card_type,
          last_4_digits: cardData.last_4_digits,
          bank_name: cardData.bank_name,
          balance: cardData.balance,
          currency: cardData.currency,
          subscriptions: {
            create: cardData.subscriptions,
          },
        },
      });
    }
  }

  console.log(`Configured ${mockCards.length} mock bank cards with pre-attached services.`);

  // 3. Default System Administrator Account
  const adminEmail = 'admin@subtracker.com';
  const adminPasswordHash = await bcrypt.hash('AdminPassword123!', 10);
  const adminPinHash = await bcrypt.hash('999999', 10);

  await prisma.user.upsert({
    where: { email: adminEmail },
    update: {
      role: 'ADMIN' as any,
      password_hash: adminPasswordHash,
      security_pin_hash: adminPinHash,
    },
    create: {
      email: adminEmail,
      name: 'System Administrator',
      password_hash: adminPasswordHash,
      security_pin_hash: adminPinHash,
      role: 'ADMIN' as any,
      monthly_income: 100000,
    },
  });
  console.log(`Configured default admin account: ${adminEmail} (password: AdminPassword123!)`);

  // 4. Test User Accounts: 'ne' and 'student01'
  const defaultPasswordHash = await bcrypt.hash('Password123!', 10);

  // User 'ne'
  const neEmail = 'ne@example.com';
  const nePinHash = await bcrypt.hash('123456', 10);
  const userNe = await prisma.user.upsert({
    where: { email: neEmail },
    update: {
      name: 'ne',
      monthly_income: 45000,
      password_hash: defaultPasswordHash,
      security_pin_hash: nePinHash,
    },
    create: {
      email: neEmail,
      name: 'ne',
      monthly_income: 45000,
      password_hash: defaultPasswordHash,
      security_pin_hash: nePinHash,
    },
  });
  console.log(`Configured test user: ${neEmail} (name: ne, monthly_income: 45000)`);

  // User 'student01'
  const studentEmail = 'student01@example.com';
  const studentPinHash = await bcrypt.hash('111111', 10);
  const userStudent = await prisma.user.upsert({
    where: { email: studentEmail },
    update: {
      name: 'student01',
      monthly_income: 15000,
      password_hash: defaultPasswordHash,
      security_pin_hash: studentPinHash,
    },
    create: {
      email: studentEmail,
      name: 'student01',
      monthly_income: 15000,
      password_hash: defaultPasswordHash,
      security_pin_hash: studentPinHash,
    },
  });
  console.log(`Configured test user: ${studentEmail} (name: student01, monthly_income: 15000)`);

  // 5. Test Payment Cards
  const neCardId = 'c0000000-0000-4000-a000-000000000001';
  await prisma.paymentCard.upsert({
    where: { id: neCardId },
    update: {
      user_id: userNe.id,
      card_nickname: 'Ne SCB Platinum',
      card_brand: 'Visa',
      card_type: CardType.CREDIT,
      last_4_digits: '4321',
      bank_name: 'Siam Commercial Bank',
      balance: 25000.0,
      currency: 'THB',
      is_default: true,
      is_active: true,
    },
    create: {
      id: neCardId,
      user_id: userNe.id,
      card_nickname: 'Ne SCB Platinum',
      card_brand: 'Visa',
      card_type: CardType.CREDIT,
      last_4_digits: '4321',
      bank_name: 'Siam Commercial Bank',
      balance: 25000.0,
      currency: 'THB',
      is_default: true,
      is_active: true,
    },
  });

  const studentCardId = 'c0000000-0000-4000-a000-000000000002';
  await prisma.paymentCard.upsert({
    where: { id: studentCardId },
    update: {
      user_id: userStudent.id,
      card_nickname: 'Student KBank Debit',
      card_brand: 'Mastercard',
      card_type: CardType.DEBIT,
      last_4_digits: '1234',
      bank_name: 'Kasikornbank',
      balance: 5000.0,
      currency: 'THB',
      is_default: true,
      is_active: true,
    },
    create: {
      id: studentCardId,
      user_id: userStudent.id,
      card_nickname: 'Student KBank Debit',
      card_brand: 'Mastercard',
      card_type: CardType.DEBIT,
      last_4_digits: '1234',
      bank_name: 'Kasikornbank',
      balance: 5000.0,
      currency: 'THB',
      is_default: true,
      is_active: true,
    },
  });

  console.log(`Configured test payment cards: ${neCardId} (ne) and ${studentCardId} (student01)`);

  console.log('Seeding completed successfully.');
}

main()
  .catch((e) => {
    console.error('Seeding error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
