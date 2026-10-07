import {
  PrismaClient,
  CardType,
  BillingCycle,
  UsageStatus,
  SubscriptionStatus,
  UserRole,
} from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database with Subscription Presets, Mock Bank Cards, Users, and Payment Cards...');

  // --------------------------------------------------------------------------
  // 1. Subscription Presets Catalog (26 Popular Subscriptions in Thailand & Globally)
  // --------------------------------------------------------------------------
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
        { tier: 'Student', monthly_price: 109.0, yearly_price: null, max_slots: 1, features: ['Student verification required', 'Ad-free', 'Background play'] },
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
        { tier: 'Team', monthly_price: 890.0, yearly_price: 8900.0, max_slots: 5, features: ['Higher rate limits', 'Admin console', 'Team workspace', 'Data excluded from training'] },
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
      max_slots: 4,
      features: ['Disney, Pixar, Marvel, Star Wars & Nat Geo', 'Full HD & 4K streaming'],
      available_plans: [
        { tier: 'Basic', monthly_price: 99.0, yearly_price: 790.0, max_slots: 1, features: ['720p HD', '1 Screen (Phone/Tablet/Laptop)'] },
        { tier: 'Standard', monthly_price: 289.0, yearly_price: 2890.0, max_slots: 2, features: ['1080p Full HD', '2 Screens simultaneously'] },
        { tier: 'Premium', monthly_price: 329.0, yearly_price: 3290.0, max_slots: 4, features: ['4K UHD + Dolby Vision', '4 Screens simultaneously'] },
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
      max_slots: 5,
      features: ['Apple Music', 'Apple TV+', 'Apple Arcade', '50GB iCloud storage'],
      available_plans: [
        { tier: 'Individual', monthly_price: 379.0, yearly_price: null, max_slots: 1, features: ['Apple Music', 'Apple TV+', 'Apple Arcade', '50GB iCloud storage'] },
        { tier: 'Family', monthly_price: 529.0, yearly_price: null, max_slots: 5, features: ['Share with up to 5 people', '200GB iCloud storage', 'Separate accounts'] },
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
      max_slots: 5,
      features: ['200GB cloud storage', 'Private Relay', 'Hide My Email', 'Custom email domain'],
      available_plans: [
        { tier: '50GB', monthly_price: 35.0, yearly_price: null, max_slots: 1, features: ['50GB storage', 'Private Relay', 'Hide My Email'] },
        { tier: '200GB', monthly_price: 99.0, yearly_price: null, max_slots: 5, features: ['200GB storage', 'Share with family', 'Private Relay', 'Hide My Email'] },
        { tier: '2TB', monthly_price: 349.0, yearly_price: null, max_slots: 5, features: ['2TB storage', 'Share with family', 'HomeKit Secure Video'] },
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
      features: ['AI code completions', 'In-IDE chat', 'CLI assistance'],
      available_plans: [
        { tier: 'Individual', monthly_price: 350.0, yearly_price: 3500.0, max_slots: 1, features: ['Code completions', 'Copilot Chat in IDE'] },
        { tier: 'Business', monthly_price: 670.0, yearly_price: 6700.0, max_slots: 1, features: ['Organization policy management', 'IP indemnity', 'Proxy support'] },
      ],
    },
    {
      name: 'Amazon Prime Video',
      category: 'Streaming',
      default_price: 149.0,
      billing_cycle: BillingCycle.MONTHLY,
      brand_color: '#00A8E1',
      icon_url: 'https://www.primevideo.com/favicon.ico',
      description: 'Amazon Originals, award-winning movies and TV shows in 4K UHD.',
      max_slots: 3,
      features: ['4K UHD + HDR', '3 simultaneous streams', 'X-Ray insights', 'Offline download'],
      available_plans: [
        { tier: 'Standard', monthly_price: 149.0, yearly_price: 1490.0, max_slots: 3, features: ['4K streaming', 'Up to 3 streams', 'Download to watch offline'] },
      ],
    },
    {
      name: 'HBO GO',
      category: 'Streaming',
      default_price: 199.0,
      billing_cycle: BillingCycle.MONTHLY,
      brand_color: '#5C2D91',
      icon_url: 'https://www.hbogo.co.th/favicon.ico',
      description: 'Blockbuster movies, HBO originals, Warner Bros films, and DC Universe.',
      max_slots: 3,
      features: ['HBO Originals', 'Warner Bros blockbusters', 'Up to 3 devices', 'Download'],
      available_plans: [
        { tier: 'Monthly', monthly_price: 199.0, yearly_price: null, max_slots: 3, features: ['Full HD', '3 devices simultaneous', 'Unlimited downloads'] },
        { tier: 'Annual', monthly_price: 99.0, yearly_price: 1190.0, max_slots: 3, features: ['1,190 THB / year (save 50%)', 'Full HD', '3 devices'] },
      ],
    },
    {
      name: 'Viu Premium',
      category: 'Streaming',
      default_price: 149.0,
      billing_cycle: BillingCycle.MONTHLY,
      brand_color: '#F9B200',
      icon_url: 'https://www.viu.com/favicon.ico',
      description: 'Express Korean dramas, variety shows, and Asian entertainment with Thai dub/sub.',
      max_slots: 5,
      features: ['Express Korean drama 8h after broadcast', 'Full HD 1080p', 'No ads', 'Thai Dubbing'],
      available_plans: [
        { tier: 'Monthly', monthly_price: 149.0, yearly_price: null, max_slots: 5, features: ['1080p Full HD', 'No ads', 'Simultaneous 5 screens'] },
        { tier: 'Annual', monthly_price: 119.0, yearly_price: 1190.0, max_slots: 5, features: ['1,190 THB / year', 'Priority server', 'Unlimited downloads'] },
      ],
    },
    {
      name: 'iQIYI VIP',
      category: 'Streaming',
      default_price: 119.0,
      billing_cycle: BillingCycle.MONTHLY,
      brand_color: '#00C853',
      icon_url: 'https://www.iq.com/favicon.ico',
      description: 'Popular Chinese dramas, anime, and exclusive Asian entertainment.',
      max_slots: 4,
      features: ['Skip video ads', '1080p/4K Dolby Atmos', 'Exclusive early access episodes'],
      available_plans: [
        { tier: 'Standard VIP', monthly_price: 119.0, yearly_price: 1190.0, max_slots: 2, features: ['1080p Full HD', '2 Screens simultaneously', 'Ad-free'] },
        { tier: 'Premium VIP', monthly_price: 199.0, yearly_price: 1990.0, max_slots: 4, features: ['4K + Dolby Vision & Atmos', '4 Screens simultaneously'] },
      ],
    },
    {
      name: 'WeTV VIP',
      category: 'Streaming',
      default_price: 119.0,
      billing_cycle: BillingCycle.MONTHLY,
      brand_color: '#FF6F00',
      icon_url: 'https://wetv.vip/favicon.ico',
      description: 'Tencent Video top Asian dramas, mini-series, anime, and variety shows.',
      max_slots: 2,
      features: ['Early access to episodes', '1080p Full HD', 'No video ads', 'Download offline'],
      available_plans: [
        { tier: 'Monthly VIP', monthly_price: 119.0, yearly_price: null, max_slots: 2, features: ['2 Screens', 'Ad-free', '1080p Blu-ray'] },
        { tier: 'Annual VIP', monthly_price: 100.0, yearly_price: 1200.0, max_slots: 2, features: ['Full 12 months access', 'All VIP perks'] },
      ],
    },
    {
      name: 'Claude Pro',
      category: 'Productivity',
      default_price: 720.0,
      billing_cycle: BillingCycle.MONTHLY,
      brand_color: '#D97706',
      icon_url: 'https://claude.ai/favicon.ico',
      description: '5x more usage of Claude 3.5 Sonnet, priority bandwidth during peak hours, Projects.',
      max_slots: 1,
      features: ['Claude 3.5 Sonnet & Haiku', 'Artifacts & Projects', 'Extended context window', 'Priority access'],
      available_plans: [
        { tier: 'Pro', monthly_price: 720.0, yearly_price: null, max_slots: 1, features: ['At least 5x usage vs free', 'Claude 3.5 Sonnet priority', 'Early access to features'] },
        { tier: 'Team', monthly_price: 900.0, yearly_price: 9000.0, max_slots: 5, features: ['Higher usage limits', 'Central billing & admin', 'Shared projects'] },
      ],
    },
    {
      name: 'Midjourney Standard',
      category: 'Design',
      default_price: 1080.0,
      billing_cycle: BillingCycle.MONTHLY,
      brand_color: '#1E1E2E',
      icon_url: 'https://www.midjourney.com/favicon.ico',
      description: 'State-of-the-art AI image generation with 15h Fast GPU time and unlimited Relax GPU.',
      max_slots: 1,
      features: ['15 hr/month Fast GPU time', 'Unlimited Relax GPU generations', 'General commercial terms'],
      available_plans: [
        { tier: 'Basic', monthly_price: 360.0, yearly_price: 3600.0, max_slots: 1, features: ['3.3 hr Fast GPU/month', 'Commercial usage'] },
        { tier: 'Standard', monthly_price: 1080.0, yearly_price: 10800.0, max_slots: 1, features: ['15 hr Fast GPU/month', 'Unlimited Relax GPU', 'Member gallery'] },
        { tier: 'Pro', monthly_price: 2160.0, yearly_price: 21600.0, max_slots: 1, features: ['30 hr Fast GPU/month', 'Stealth mode generation'] },
      ],
    },
    {
      name: 'Canva Pro',
      category: 'Design',
      default_price: 290.0,
      billing_cycle: BillingCycle.MONTHLY,
      brand_color: '#00C4CC',
      icon_url: 'https://static.canva.com/static/images/favicon.ico',
      description: 'Unlimited premium templates, 100M+ stock photos, Magic Studio AI tools, brand kits.',
      max_slots: 5,
      features: ['Magic Studio AI tools', 'One-click Background Remover', '100M+ stock assets', '1TB cloud storage'],
      available_plans: [
        { tier: 'Individual', monthly_price: 290.0, yearly_price: 2290.0, max_slots: 1, features: ['Magic Studio AI', '100M+ premium assets', '1TB storage'] },
        { tier: 'Teams', monthly_price: 540.0, yearly_price: 4990.0, max_slots: 5, features: ['Team brand kits', 'Approval workflows', 'Real-time collaboration'] },
      ],
    },
    {
      name: 'Adobe Creative Cloud',
      category: 'Design',
      default_price: 1150.0,
      billing_cycle: BillingCycle.MONTHLY,
      brand_color: '#FA0F00',
      icon_url: 'https://www.adobe.com/favicon.ico',
      description: 'Complete suite: Photoshop, Illustrator, Premiere Pro, After Effects, Lightroom and more.',
      max_slots: 1,
      features: ['20+ desktop & mobile creative apps', '100GB cloud storage', 'Adobe Fonts', 'Generative Firefly credits'],
      available_plans: [
        { tier: 'Photography', monthly_price: 380.0, yearly_price: 4560.0, max_slots: 1, features: ['Photoshop + Lightroom', '20GB Cloud Storage'] },
        { tier: 'All Apps', monthly_price: 1150.0, yearly_price: 13800.0, max_slots: 1, features: ['20+ creative apps', '100GB Cloud', 'Adobe Firefly AI credits'] },
      ],
    },
    {
      name: 'Figma Professional',
      category: 'Design',
      default_price: 540.0,
      billing_cycle: BillingCycle.MONTHLY,
      brand_color: '#F24E1E',
      icon_url: 'https://static.figma.com/app/icon/1/favicon.ico',
      description: 'Collaborative interface design, unlimited version history, advanced prototyping, and dev mode.',
      max_slots: 1,
      features: ['Unlimited Figma files & version history', 'Shared team libraries', 'Advanced prototyping & Dev Mode'],
      available_plans: [
        { tier: 'Professional', monthly_price: 540.0, yearly_price: 5400.0, max_slots: 1, features: ['Unlimited files', 'Team libraries', 'Dev Mode access'] },
        { tier: 'Organization', monthly_price: 1600.0, yearly_price: 19200.0, max_slots: 1, features: ['Org-wide design systems', 'Branching & merging', 'Centralized analytics'] },
      ],
    },
    {
      name: 'Notion Plus',
      category: 'Productivity',
      default_price: 360.0,
      billing_cycle: BillingCycle.MONTHLY,
      brand_color: '#000000',
      icon_url: 'https://www.notion.so/images/favicon.ico',
      description: 'Connected workspace for wiki, docs, and projects with unlimited blocks and file uploads.',
      max_slots: 1,
      features: ['Unlimited blocks for teams', 'Unlimited file uploads', '30-day page history', '100 guest invites'],
      available_plans: [
        { tier: 'Plus', monthly_price: 360.0, yearly_price: 3600.0, max_slots: 1, features: ['Unlimited blocks', 'Unlimited file uploads', 'Up to 100 guests'] },
        { tier: 'Business', monthly_price: 650.0, yearly_price: 6500.0, max_slots: 1, features: ['SAML SSO', 'Private teamspaces', '90-day page history'] },
      ],
    },
    {
      name: 'Microsoft 365 Personal',
      category: 'Productivity',
      default_price: 219.0,
      billing_cycle: BillingCycle.MONTHLY,
      brand_color: '#D83B01',
      icon_url: 'https://www.microsoft.com/favicon.ico',
      description: 'Premium Office apps (Word, Excel, PowerPoint), 1TB OneDrive cloud storage, advanced security.',
      max_slots: 1,
      features: ['Word, Excel, PowerPoint, Outlook', '1TB OneDrive cloud storage', 'Ransomware detection', 'Works on PC, Mac, iOS, Android'],
      available_plans: [
        { tier: 'Personal', monthly_price: 219.0, yearly_price: 2190.0, max_slots: 1, features: ['1 Person', '1TB cloud storage', 'Premium Office apps'] },
        { tier: 'Family', monthly_price: 289.0, yearly_price: 2890.0, max_slots: 6, features: ['Up to 6 people', '6TB total storage (1TB each)', 'Family Safety app'] },
      ],
    },
    {
      name: 'Google One 100GB',
      category: 'Cloud',
      default_price: 70.0,
      billing_cycle: BillingCycle.MONTHLY,
      brand_color: '#4285F4',
      icon_url: 'https://one.google.com/favicon.ico',
      description: '100GB expanded storage across Google Drive, Gmail, and Google Photos with family sharing.',
      max_slots: 5,
      features: ['100GB storage across Drive, Gmail, Photos', 'Share with up to 5 family members', 'Google experts support'],
      available_plans: [
        { tier: 'Basic 100GB', monthly_price: 70.0, yearly_price: 700.0, max_slots: 5, features: ['100GB storage', 'Share with family'] },
        { tier: 'Standard 200GB', monthly_price: 99.0, yearly_price: 990.0, max_slots: 5, features: ['200GB storage', '3% Google Store back'] },
        { tier: 'Premium 2TB', monthly_price: 350.0, yearly_price: 3500.0, max_slots: 5, features: ['2TB storage', '10% Google Store back', 'Google Meet premium perks'] },
      ],
    },
    {
      name: 'Dropbox Plus',
      category: 'Cloud',
      default_price: 420.0,
      billing_cycle: BillingCycle.MONTHLY,
      brand_color: '#0061FF',
      icon_url: 'https://www.dropbox.com/favicon.ico',
      description: '2TB encrypted cloud storage, Dropbox Rewind, smart sync, and file transfer up to 2GB.',
      max_slots: 1,
      features: ['2TB cloud storage space', 'Dropbox Passwords vault', 'Dropbox Rewind (30 days)', 'Send files up to 2GB'],
      available_plans: [
        { tier: 'Plus', monthly_price: 420.0, yearly_price: 4200.0, max_slots: 1, features: ['2TB storage', 'Unlimited device sync', '30-day file recovery'] },
        { tier: 'Family', monthly_price: 670.0, yearly_price: 6700.0, max_slots: 6, features: ['2TB shared between 6 members', 'Private & shared folders'] },
      ],
    },
    {
      name: 'Duolingo Super',
      category: 'Education',
      default_price: 209.0,
      billing_cycle: BillingCycle.MONTHLY,
      brand_color: '#58CC02',
      icon_url: 'https://www.duolingo.com/favicon.ico',
      description: 'Ad-free language learning, unlimited hearts, personalized mistakes review, and monthly streak repair.',
      max_slots: 1,
      features: ['Unlimited hearts', 'No ads interruptions', 'Mistakes practice sessions', 'Legendary challenge access'],
      available_plans: [
        { tier: 'Super Individual', monthly_price: 209.0, yearly_price: 1790.0, max_slots: 1, features: ['Unlimited hearts', 'Ad-free experience', 'Progress tracking'] },
        { tier: 'Super Family', monthly_price: 329.0, yearly_price: 2690.0, max_slots: 6, features: ['Up to 6 accounts', 'Shared dashboard', 'All Super perks'] },
      ],
    },
    {
      name: 'Nintendo Switch Online',
      category: 'Gaming',
      default_price: 130.0,
      billing_cycle: BillingCycle.MONTHLY,
      brand_color: '#E60012',
      icon_url: 'https://www.nintendo.com/favicon.ico',
      description: 'Online multiplayer play, classic NES & SNES games catalog, cloud save data backup.',
      max_slots: 1,
      features: ['Online multiplayer gaming', 'Classic NES & Super NES games library', 'Save Data Cloud backup', 'Smartphone app voice chat'],
      available_plans: [
        { tier: 'Individual', monthly_price: 130.0, yearly_price: 690.0, max_slots: 1, features: ['Online play', 'NES/SNES/Game Boy retro games', 'Cloud saves'] },
        { tier: 'Expansion Pack', monthly_price: 180.0, yearly_price: 1650.0, max_slots: 1, features: ['N64 & GBA games', 'Mario Kart 8 Deluxe Booster Pass', 'Sega Genesis games'] },
        { tier: 'Family Expansion', monthly_price: 270.0, yearly_price: 2690.0, max_slots: 8, features: ['Up to 8 Nintendo Accounts', 'All Expansion Pack benefits'] },
      ],
    },
    {
      name: 'PlayStation Plus Extra',
      category: 'Gaming',
      default_price: 390.0,
      billing_cycle: BillingCycle.MONTHLY,
      brand_color: '#003791',
      icon_url: 'https://www.playstation.com/favicon.ico',
      description: 'Game Catalog with hundreds of PS4 & PS5 titles, monthly games, online multiplayer, cloud storage.',
      max_slots: 1,
      features: ['Game Catalog of 400+ PS4 & PS5 games', 'Monthly downloadable games', 'Online multiplayer access', 'Exclusive PS Store discounts'],
      available_plans: [
        { tier: 'Essential', monthly_price: 210.0, yearly_price: 1830.0, max_slots: 1, features: ['Monthly games', 'Online multiplayer', 'Cloud storage'] },
        { tier: 'Extra', monthly_price: 390.0, yearly_price: 3070.0, max_slots: 1, features: ['Essential perks', 'Game Catalog of hundreds of PS4/PS5 games', 'Ubisoft+ Classics'] },
        { tier: 'Deluxe', monthly_price: 450.0, yearly_price: 3530.0, max_slots: 1, features: ['Extra perks', 'Classics Catalog (PS1, PS2, PSP)', 'Game trials demo'] },
      ],
    },
    {
      name: 'Xbox Game Pass Ultimate',
      category: 'Gaming',
      default_price: 330.0,
      billing_cycle: BillingCycle.MONTHLY,
      brand_color: '#107C10',
      icon_url: 'https://www.xbox.com/favicon.ico',
      description: 'Hundreds of high-quality games on PC, console, cloud, day-one releases, and EA Play membership.',
      max_slots: 1,
      features: ['Day-one new release titles', 'Hundreds of games on PC and Console', 'EA Play membership included', 'Xbox Cloud Gaming'],
      available_plans: [
        { tier: 'PC Game Pass', monthly_price: 189.0, yearly_price: null, max_slots: 1, features: ['PC game library', 'Day-one Xbox Game Studios releases', 'EA Play on PC'] },
        { tier: 'Ultimate', monthly_price: 330.0, yearly_price: null, max_slots: 1, features: ['PC + Console + Cloud gaming', 'EA Play included', 'Perks and exclusive member discounts'] },
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

  // --------------------------------------------------------------------------
  // 2. Mock Bank Cards (10 Cards: 7 with subscriptions, 3 without subscriptions)
  // --------------------------------------------------------------------------
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
    {
      card_nickname: 'Krungsri Signature',
      card_brand: 'Visa',
      card_type: CardType.CREDIT,
      last_4_digits: '6666',
      bank_name: 'Bank of Ayudhya',
      balance: 35000.0,
      currency: 'THB',
      subscriptions: [
        {
          name: 'Claude Pro',
          category: 'Productivity',
          price: 720.0,
          billing_cycle: BillingCycle.MONTHLY,
          brand_color: '#D97706',
        },
        {
          name: 'Midjourney Standard',
          category: 'Design',
          price: 1080.0,
          billing_cycle: BillingCycle.MONTHLY,
          brand_color: '#1E1E2E',
        },
      ],
    },
    {
      card_nickname: 'KTC Platinum Visa',
      card_brand: 'Visa',
      card_type: CardType.CREDIT,
      last_4_digits: '5555',
      bank_name: 'Krungthai Bank',
      balance: 28000.0,
      currency: 'THB',
      subscriptions: [
        {
          name: 'Canva Pro',
          category: 'Design',
          price: 290.0,
          billing_cycle: BillingCycle.MONTHLY,
          brand_color: '#00C4CC',
        },
        {
          name: 'Notion Plus',
          category: 'Productivity',
          price: 360.0,
          billing_cycle: BillingCycle.MONTHLY,
          brand_color: '#000000',
        },
      ],
    },
    {
      card_nickname: 'TTB All Free',
      card_brand: 'Visa',
      card_type: CardType.DEBIT,
      last_4_digits: '4444',
      bank_name: 'TMBThanachart',
      balance: 12000.0,
      currency: 'THB',
      subscriptions: [
        {
          name: 'Nintendo Switch Online',
          category: 'Gaming',
          price: 130.0,
          billing_cycle: BillingCycle.MONTHLY,
          brand_color: '#E60012',
        },
      ],
    },
    {
      card_nickname: 'UOB Preferred',
      card_brand: 'Mastercard',
      card_type: CardType.CREDIT,
      last_4_digits: '3333',
      bank_name: 'UOB',
      balance: 50000.0,
      currency: 'THB',
      subscriptions: [
        {
          name: 'PlayStation Plus Extra',
          category: 'Gaming',
          price: 390.0,
          billing_cycle: BillingCycle.MONTHLY,
          brand_color: '#003791',
        },
      ],
    },
    // Mock cards WITHOUT any subscriptions:
    {
      card_nickname: 'GSB Debit Smart Life',
      card_brand: 'Mastercard',
      card_type: CardType.DEBIT,
      last_4_digits: '2222',
      bank_name: 'Government Savings Bank',
      balance: 7000.0,
      currency: 'THB',
      subscriptions: [], // No subscriptions
    },
    {
      card_nickname: 'CIMB Chill D Debit',
      card_brand: 'Visa',
      card_type: CardType.DEBIT,
      last_4_digits: '1111',
      bank_name: 'CIMB Thai',
      balance: 3500.0,
      currency: 'THB',
      subscriptions: [], // No subscriptions
    },
    {
      card_nickname: 'Bangkok Bank Digital e-Savings',
      card_brand: 'Mastercard',
      card_type: CardType.DEBIT,
      last_4_digits: '0000',
      bank_name: 'Bangkok Bank',
      balance: 92000.0,
      currency: 'THB',
      subscriptions: [], // No subscriptions
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

      // Synchronize mock subscriptions cleanly
      await prisma.mockBankCardSubscription.deleteMany({
        where: { mock_bank_card_id: existing.id },
      });
      if (cardData.subscriptions.length > 0) {
        await prisma.mockBankCardSubscription.createMany({
          data: cardData.subscriptions.map((s) => ({
            mock_bank_card_id: existing.id,
            name: s.name,
            category: s.category,
            price: s.price,
            billing_cycle: s.billing_cycle,
            brand_color: s.brand_color,
          })),
        });
      }
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

  console.log(`Configured ${mockCards.length} mock bank cards (with and without pre-attached services).`);

  // --------------------------------------------------------------------------
  // 3. Admin Account + 5 User Accounts (Total 6 accounts)
  // --------------------------------------------------------------------------
  const adminEmail = 'admin@subtracker.com';
  const adminPasswordHash = await bcrypt.hash('AdminPassword123!', 10);
  const adminPinHash = await bcrypt.hash('999999', 10);

  await prisma.user.upsert({
    where: { email: adminEmail },
    update: {
      role: UserRole.ADMIN,
      password_hash: adminPasswordHash,
      security_pin_hash: adminPinHash,
    },
    create: {
      email: adminEmail,
      name: 'System Administrator',
      password_hash: adminPasswordHash,
      security_pin_hash: adminPinHash,
      role: UserRole.ADMIN,
      monthly_income: 100000,
    },
  });
  console.log(`Configured default admin account: ${adminEmail}`);

  const defaultPasswordHash = await bcrypt.hash('Password123!', 10);

  // 5 Active Users
  const usersList = [
    { email: 'ne@example.com', name: 'ne', monthly_income: 45000, pin: '123456' },
    { email: 'student01@example.com', name: 'student01', monthly_income: 15000, pin: '111111' },
    { email: 'somchai@example.com', name: 'Somchai Dev', monthly_income: 65000, pin: '222222' },
    { email: 'ploy@example.com', name: 'Ploy Creative', monthly_income: 38000, pin: '333333' },
    { email: 'anan@example.com', name: 'Anan Gamer', monthly_income: 52000, pin: '444444' },
  ];

  const createdUsers: Record<string, any> = {};

  for (const u of usersList) {
    const pinHash = await bcrypt.hash(u.pin, 10);
    const userRecord = await prisma.user.upsert({
      where: { email: u.email },
      update: {
        name: u.name,
        monthly_income: u.monthly_income,
        password_hash: defaultPasswordHash,
        security_pin_hash: pinHash,
      },
      create: {
        email: u.email,
        name: u.name,
        monthly_income: u.monthly_income,
        password_hash: defaultPasswordHash,
        security_pin_hash: pinHash,
        role: UserRole.USER,
      },
    });
    createdUsers[u.email] = userRecord;
    console.log(`Configured user: ${u.email} (${u.name}, income: ${u.monthly_income})`);
  }

  // --------------------------------------------------------------------------
  // 4. Test Payment Cards (10 Cards: Some with Subscriptions, Some without)
  // --------------------------------------------------------------------------
  const paymentCardsData = [
    // User 'ne'
    {
      id: 'c0000000-0000-4000-a000-000000000001',
      userId: createdUsers['ne@example.com'].id,
      card_nickname: 'Ne SCB Platinum',
      card_brand: 'Visa',
      card_type: CardType.CREDIT,
      last_4_digits: '4321',
      bank_name: 'Siam Commercial Bank',
      balance: 25000.0,
      currency: 'THB',
      is_default: true,
      hasSubscriptions: true,
    },
    {
      id: 'c0000000-0000-4000-a000-000000000002',
      userId: createdUsers['ne@example.com'].id,
      card_nickname: 'Ne KBank Everyday',
      card_brand: 'Mastercard',
      card_type: CardType.DEBIT,
      last_4_digits: '8765',
      bank_name: 'Kasikornbank',
      balance: 12000.0,
      currency: 'THB',
      is_default: false,
      hasSubscriptions: false, // NO SUBSCRIPTION
    },
    // User 'student01'
    {
      id: 'c0000000-0000-4000-a000-000000000003',
      userId: createdUsers['student01@example.com'].id,
      card_nickname: 'Student KBank Debit',
      card_brand: 'Mastercard',
      card_type: CardType.DEBIT,
      last_4_digits: '1234',
      bank_name: 'Kasikornbank',
      balance: 5000.0,
      currency: 'THB',
      is_default: true,
      hasSubscriptions: true,
    },
    {
      id: 'c0000000-0000-4000-a000-000000000004',
      userId: createdUsers['student01@example.com'].id,
      card_nickname: 'Student TrueMoney Virtual',
      card_brand: 'Visa',
      card_type: CardType.DEBIT,
      last_4_digits: '9876',
      bank_name: 'TrueMoney',
      balance: 1500.0,
      currency: 'THB',
      is_default: false,
      hasSubscriptions: false, // NO SUBSCRIPTION
    },
    // User 'somchai'
    {
      id: 'c0000000-0000-4000-a000-000000000005',
      userId: createdUsers['somchai@example.com'].id,
      card_nickname: 'Somchai KTC Digital',
      card_brand: 'Visa',
      card_type: CardType.CREDIT,
      last_4_digits: '5432',
      bank_name: 'Krungthai Bank',
      balance: 45000.0,
      currency: 'THB',
      is_default: true,
      hasSubscriptions: true,
    },
    {
      id: 'c0000000-0000-4000-a000-000000000006',
      userId: createdUsers['somchai@example.com'].id,
      card_nickname: 'Somchai BBL Payroll',
      card_brand: 'Mastercard',
      card_type: CardType.DEBIT,
      last_4_digits: '2345',
      bank_name: 'Bangkok Bank',
      balance: 68000.0,
      currency: 'THB',
      is_default: false,
      hasSubscriptions: false, // NO SUBSCRIPTION
    },
    // User 'ploy'
    {
      id: 'c0000000-0000-4000-a000-000000000007',
      userId: createdUsers['ploy@example.com'].id,
      card_nickname: 'Ploy Krungsri Now',
      card_brand: 'Visa',
      card_type: CardType.CREDIT,
      last_4_digits: '6789',
      bank_name: 'Bank of Ayudhya',
      balance: 32000.0,
      currency: 'THB',
      is_default: true,
      hasSubscriptions: true,
    },
    {
      id: 'c0000000-0000-4000-a000-000000000008',
      userId: createdUsers['ploy@example.com'].id,
      card_nickname: 'Ploy SCB Debit',
      card_brand: 'Mastercard',
      card_type: CardType.DEBIT,
      last_4_digits: '3456',
      bank_name: 'Siam Commercial Bank',
      balance: 15000.0,
      currency: 'THB',
      is_default: false,
      hasSubscriptions: false, // NO SUBSCRIPTION
    },
    // User 'anan'
    {
      id: 'c0000000-0000-4000-a000-000000000009',
      userId: createdUsers['anan@example.com'].id,
      card_nickname: 'Anan UOB One',
      card_brand: 'Mastercard',
      card_type: CardType.CREDIT,
      last_4_digits: '7890',
      bank_name: 'UOB',
      balance: 40000.0,
      currency: 'THB',
      is_default: true,
      hasSubscriptions: true,
    },
    {
      id: 'c0000000-0000-4000-a000-000000000010',
      userId: createdUsers['anan@example.com'].id,
      card_nickname: 'Anan TTB Reserve',
      card_brand: 'Visa',
      card_type: CardType.DEBIT,
      last_4_digits: '8901',
      bank_name: 'TMBThanachart',
      balance: 28000.0,
      currency: 'THB',
      is_default: false,
      hasSubscriptions: false, // NO SUBSCRIPTION
    },
  ];

  for (const c of paymentCardsData) {
    await prisma.paymentCard.upsert({
      where: { id: c.id },
      update: {
        user_id: c.userId,
        card_nickname: c.card_nickname,
        card_brand: c.card_brand,
        card_type: c.card_type,
        last_4_digits: c.last_4_digits,
        bank_name: c.bank_name,
        balance: c.balance,
        currency: c.currency,
        is_default: c.is_default,
        is_active: true,
      },
      create: {
        id: c.id,
        user_id: c.userId,
        card_nickname: c.card_nickname,
        card_brand: c.card_brand,
        card_type: c.card_type,
        last_4_digits: c.last_4_digits,
        bank_name: c.bank_name,
        balance: c.balance,
        currency: c.currency,
        is_default: c.is_default,
        is_active: true,
      },
    });
  }

  console.log(`Configured ${paymentCardsData.length} test payment cards.`);

  // --------------------------------------------------------------------------
  // 5. Active User Subscriptions Attached to Cards with Subscriptions
  // --------------------------------------------------------------------------
  const allPresets = await prisma.subscriptionPreset.findMany();
  const presetMap = new Map(allPresets.map((p) => [p.name, p]));

  const now = new Date();
  const oneMonthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
  const nextTwoWeeks = new Date(now.getTime() + 14 * 24 * 60 * 60 * 1000);
  const nextThreeWeeks = new Date(now.getTime() + 21 * 24 * 60 * 60 * 1000);
  const nextOneMonth = new Date(now.getTime() + 28 * 24 * 60 * 60 * 1000);

  const userSubscriptions = [
    // ne's Card 1 (SCB Platinum)
    {
      id: 's0000000-0000-4000-a000-000000000001',
      user_id: createdUsers['ne@example.com'].id,
      payment_card_id: 'c0000000-0000-4000-a000-000000000001',
      preset_name: 'Netflix Premium',
      plan_tier: 'Premium',
      price: 419.0,
      billing_cycle: BillingCycle.MONTHLY,
      start_date: oneMonthAgo,
      next_renewal_date: nextTwoWeeks,
      usage_status: UsageStatus.FREQUENT,
      status: SubscriptionStatus.ACTIVE,
      shared_members: 4,
      price_per_slot: 104.75,
      brand_color: '#E50914',
    },
    {
      id: 's0000000-0000-4000-a000-000000000002',
      user_id: createdUsers['ne@example.com'].id,
      payment_card_id: 'c0000000-0000-4000-a000-000000000001',
      preset_name: 'Spotify Premium',
      plan_tier: 'Individual',
      price: 139.0,
      billing_cycle: BillingCycle.MONTHLY,
      start_date: oneMonthAgo,
      next_renewal_date: nextThreeWeeks,
      usage_status: UsageStatus.FREQUENT,
      status: SubscriptionStatus.ACTIVE,
      shared_members: 1,
      price_per_slot: 139.0,
      brand_color: '#1DB954',
    },
    {
      id: 's0000000-0000-4000-a000-000000000003',
      user_id: createdUsers['ne@example.com'].id,
      payment_card_id: 'c0000000-0000-4000-a000-000000000001',
      preset_name: 'ChatGPT Plus',
      plan_tier: 'Plus',
      price: 720.0,
      billing_cycle: BillingCycle.MONTHLY,
      start_date: oneMonthAgo,
      next_renewal_date: nextOneMonth,
      usage_status: UsageStatus.FREQUENT,
      status: SubscriptionStatus.ACTIVE,
      shared_members: 1,
      price_per_slot: 720.0,
      brand_color: '#10A37F',
    },

    // student01's Card 3 (KBank Debit)
    {
      id: 's0000000-0000-4000-a000-000000000004',
      user_id: createdUsers['student01@example.com'].id,
      payment_card_id: 'c0000000-0000-4000-a000-000000000003',
      preset_name: 'YouTube Premium',
      plan_tier: 'Student',
      price: 109.0,
      billing_cycle: BillingCycle.MONTHLY,
      start_date: oneMonthAgo,
      next_renewal_date: nextTwoWeeks,
      usage_status: UsageStatus.FREQUENT,
      status: SubscriptionStatus.ACTIVE,
      shared_members: 1,
      price_per_slot: 109.0,
      brand_color: '#FF0000',
    },

    // somchai's Card 5 (KTC Digital)
    {
      id: 's0000000-0000-4000-a000-000000000005',
      user_id: createdUsers['somchai@example.com'].id,
      payment_card_id: 'c0000000-0000-4000-a000-000000000005',
      preset_name: 'GitHub Copilot',
      plan_tier: 'Individual',
      price: 350.0,
      billing_cycle: BillingCycle.MONTHLY,
      start_date: oneMonthAgo,
      next_renewal_date: nextThreeWeeks,
      usage_status: UsageStatus.FREQUENT,
      status: SubscriptionStatus.ACTIVE,
      shared_members: 1,
      price_per_slot: 350.0,
      brand_color: '#24292E',
    },
    {
      id: 's0000000-0000-4000-a000-000000000006',
      user_id: createdUsers['somchai@example.com'].id,
      payment_card_id: 'c0000000-0000-4000-a000-000000000005',
      preset_name: 'Claude Pro',
      plan_tier: 'Pro',
      price: 720.0,
      billing_cycle: BillingCycle.MONTHLY,
      start_date: oneMonthAgo,
      next_renewal_date: nextTwoWeeks,
      usage_status: UsageStatus.FREQUENT,
      status: SubscriptionStatus.ACTIVE,
      shared_members: 1,
      price_per_slot: 720.0,
      brand_color: '#D97706',
    },
    {
      id: 's0000000-0000-4000-a000-000000000007',
      user_id: createdUsers['somchai@example.com'].id,
      payment_card_id: 'c0000000-0000-4000-a000-000000000005',
      preset_name: 'Notion Plus',
      plan_tier: 'Plus',
      price: 360.0,
      billing_cycle: BillingCycle.MONTHLY,
      start_date: oneMonthAgo,
      next_renewal_date: nextOneMonth,
      usage_status: UsageStatus.OCCASIONAL,
      status: SubscriptionStatus.ACTIVE,
      shared_members: 1,
      price_per_slot: 360.0,
      brand_color: '#000000',
    },

    // ploy's Card 7 (Krungsri Now)
    {
      id: 's0000000-0000-4000-a000-000000000008',
      user_id: createdUsers['ploy@example.com'].id,
      payment_card_id: 'c0000000-0000-4000-a000-000000000007',
      preset_name: 'Canva Pro',
      plan_tier: 'Individual',
      price: 290.0,
      billing_cycle: BillingCycle.MONTHLY,
      start_date: oneMonthAgo,
      next_renewal_date: nextTwoWeeks,
      usage_status: UsageStatus.FREQUENT,
      status: SubscriptionStatus.ACTIVE,
      shared_members: 1,
      price_per_slot: 290.0,
      brand_color: '#00C4CC',
    },
    {
      id: 's0000000-0000-4000-a000-000000000009',
      user_id: createdUsers['ploy@example.com'].id,
      payment_card_id: 'c0000000-0000-4000-a000-000000000007',
      preset_name: 'Adobe Creative Cloud',
      plan_tier: 'All Apps',
      price: 1150.0,
      billing_cycle: BillingCycle.MONTHLY,
      start_date: oneMonthAgo,
      next_renewal_date: nextThreeWeeks,
      usage_status: UsageStatus.FREQUENT,
      status: SubscriptionStatus.ACTIVE,
      shared_members: 1,
      price_per_slot: 1150.0,
      brand_color: '#FA0F00',
    },
    {
      id: 's0000000-0000-4000-a000-000000000010',
      user_id: createdUsers['ploy@example.com'].id,
      payment_card_id: 'c0000000-0000-4000-a000-000000000007',
      preset_name: 'Midjourney Standard',
      plan_tier: 'Standard',
      price: 1080.0,
      billing_cycle: BillingCycle.MONTHLY,
      start_date: oneMonthAgo,
      next_renewal_date: nextOneMonth,
      usage_status: UsageStatus.FREQUENT,
      status: SubscriptionStatus.ACTIVE,
      shared_members: 1,
      price_per_slot: 1080.0,
      brand_color: '#1E1E2E',
    },

    // anan's Card 9 (UOB One)
    {
      id: 's0000000-0000-4000-a000-000000000011',
      user_id: createdUsers['anan@example.com'].id,
      payment_card_id: 'c0000000-0000-4000-a000-000000000009',
      preset_name: 'Xbox Game Pass Ultimate',
      plan_tier: 'Ultimate',
      price: 330.0,
      billing_cycle: BillingCycle.MONTHLY,
      start_date: oneMonthAgo,
      next_renewal_date: nextTwoWeeks,
      usage_status: UsageStatus.FREQUENT,
      status: SubscriptionStatus.ACTIVE,
      shared_members: 1,
      price_per_slot: 330.0,
      brand_color: '#107C10',
    },
    {
      id: 's0000000-0000-4000-a000-000000000012',
      user_id: createdUsers['anan@example.com'].id,
      payment_card_id: 'c0000000-0000-4000-a000-000000000009',
      preset_name: 'PlayStation Plus Extra',
      plan_tier: 'Extra',
      price: 390.0,
      billing_cycle: BillingCycle.MONTHLY,
      start_date: oneMonthAgo,
      next_renewal_date: nextThreeWeeks,
      usage_status: UsageStatus.FREQUENT,
      status: SubscriptionStatus.ACTIVE,
      shared_members: 1,
      price_per_slot: 390.0,
      brand_color: '#003791',
    },
    {
      id: 's0000000-0000-4000-a000-000000000013',
      user_id: createdUsers['anan@example.com'].id,
      payment_card_id: 'c0000000-0000-4000-a000-000000000009',
      preset_name: 'Nintendo Switch Online',
      plan_tier: 'Individual',
      price: 130.0,
      billing_cycle: BillingCycle.MONTHLY,
      start_date: oneMonthAgo,
      next_renewal_date: nextOneMonth,
      usage_status: UsageStatus.OCCASIONAL,
      status: SubscriptionStatus.ACTIVE,
      shared_members: 1,
      price_per_slot: 130.0,
      brand_color: '#E60012',
    },
  ];

  for (const sub of userSubscriptions) {
    const preset = presetMap.get(sub.preset_name);
    await prisma.userSubscription.upsert({
      where: { id: sub.id },
      update: {
        user_id: sub.user_id,
        payment_card_id: sub.payment_card_id,
        preset_id: preset?.id,
        name: sub.preset_name,
        category: preset?.category || 'General',
        plan_tier: sub.plan_tier,
        price: sub.price,
        shared_members: sub.shared_members,
        price_per_slot: sub.price_per_slot,
        billing_cycle: sub.billing_cycle,
        start_date: sub.start_date,
        next_renewal_date: sub.next_renewal_date,
        usage_status: sub.usage_status,
        status: sub.status,
        brand_color: sub.brand_color,
      },
      create: {
        id: sub.id,
        user_id: sub.user_id,
        payment_card_id: sub.payment_card_id,
        preset_id: preset?.id,
        name: sub.preset_name,
        category: preset?.category || 'General',
        plan_tier: sub.plan_tier,
        price: sub.price,
        shared_members: sub.shared_members,
        price_per_slot: sub.price_per_slot,
        billing_cycle: sub.billing_cycle,
        start_date: sub.start_date,
        next_renewal_date: sub.next_renewal_date,
        usage_status: sub.usage_status,
        status: sub.status,
        brand_color: sub.brand_color,
      },
    });
  }

  console.log(`Configured ${userSubscriptions.length} user subscriptions.`);
  console.log('Seeding completed successfully!');
}

main()
  .catch((e) => {
    console.error('Seeding error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
