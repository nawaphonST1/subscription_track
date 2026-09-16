"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const prisma = new client_1.PrismaClient();
async function main() {
    console.log('Seeding database with Subscription Presets and Mock Bank Cards...');
    const presets = [
        {
            name: 'Netflix Premium',
            category: 'Streaming',
            default_price: 419.0,
            billing_cycle: client_1.BillingCycle.MONTHLY,
            brand_color: '#E50914',
            icon_url: 'https://assets.nflxext.com/ffe/siteui/common/icons/nficon2016.ico',
            description: 'Ultra HD 4K streaming, 4 simultaneous screens, download on 6 devices.',
        },
        {
            name: 'Spotify Premium',
            category: 'Music',
            default_price: 139.0,
            billing_cycle: client_1.BillingCycle.MONTHLY,
            brand_color: '#1DB954',
            icon_url: 'https://open.spotifycdn.com/cdn/images/favicon.0f31d2ea.ico',
            description: 'Ad-free music listening, offline playback, on-demand playback.',
        },
        {
            name: 'YouTube Premium',
            category: 'Streaming',
            default_price: 179.0,
            billing_cycle: client_1.BillingCycle.MONTHLY,
            brand_color: '#FF0000',
            icon_url: 'https://www.youtube.com/s/desktop/9b48c66e/img/favicon.ico',
            description: 'Ad-free videos, background playback, and YouTube Music Premium.',
        },
        {
            name: 'ChatGPT Plus',
            category: 'Productivity',
            default_price: 720.0,
            billing_cycle: client_1.BillingCycle.MONTHLY,
            brand_color: '#10A37F',
            icon_url: 'https://oaistatic-cdn.azureedge.net/favicon.ico',
            description: 'Access to GPT-4o, canvas, image generation, web browsing, advanced voice.',
        },
        {
            name: 'Disney+ Hotstar',
            category: 'Streaming',
            default_price: 289.0,
            billing_cycle: client_1.BillingCycle.MONTHLY,
            brand_color: '#113CCF',
            icon_url: 'https://www.hotstar.com/favicon.ico',
            description: 'Blockbusters from Disney, Pixar, Marvel, Star Wars, and National Geographic.',
        },
        {
            name: 'Apple One',
            category: 'Entertainment',
            default_price: 379.0,
            billing_cycle: client_1.BillingCycle.MONTHLY,
            brand_color: '#000000',
            icon_url: 'https://www.apple.com/favicon.ico',
            description: 'Apple Music, Apple TV+, Apple Arcade, and 50GB iCloud storage bundle.',
        },
        {
            name: 'iCloud+ 200GB',
            category: 'Cloud',
            default_price: 99.0,
            billing_cycle: client_1.BillingCycle.MONTHLY,
            brand_color: '#3399FF',
            icon_url: 'https://www.icloud.com/favicon.ico',
            description: '200GB cloud storage, Private Relay, Hide My Email, custom email domain.',
        },
        {
            name: 'GitHub Copilot',
            category: 'Development',
            default_price: 350.0,
            billing_cycle: client_1.BillingCycle.MONTHLY,
            brand_color: '#24292E',
            icon_url: 'https://github.githubassets.com/favicons/favicon.png',
            description: 'AI pair programmer providing code completions and chat in your IDE.',
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
    const mockCards = [
        {
            card_nickname: 'KBank Platinum Debit',
            card_brand: 'Visa',
            card_type: client_1.CardType.DEBIT,
            last_4_digits: '9999',
            bank_name: 'Kasikornbank',
            balance: 15000.0,
            currency: 'THB',
            subscriptions: [
                {
                    name: 'Netflix Premium',
                    category: 'Streaming',
                    price: 419.0,
                    billing_cycle: client_1.BillingCycle.MONTHLY,
                    brand_color: '#E50914',
                },
                {
                    name: 'Spotify Premium',
                    category: 'Music',
                    price: 139.0,
                    billing_cycle: client_1.BillingCycle.MONTHLY,
                    brand_color: '#1DB954',
                },
                {
                    name: 'ChatGPT Plus',
                    category: 'Productivity',
                    price: 720.0,
                    billing_cycle: client_1.BillingCycle.MONTHLY,
                    brand_color: '#10A37F',
                },
            ],
        },
        {
            card_nickname: 'SCB Ultra Platinum',
            card_brand: 'Mastercard',
            card_type: client_1.CardType.CREDIT,
            last_4_digits: '8888',
            bank_name: 'Siam Commercial Bank',
            balance: 45000.0,
            currency: 'THB',
            subscriptions: [
                {
                    name: 'Disney+ Hotstar',
                    category: 'Streaming',
                    price: 289.0,
                    billing_cycle: client_1.BillingCycle.MONTHLY,
                    brand_color: '#113CCF',
                },
                {
                    name: 'Apple One',
                    category: 'Entertainment',
                    price: 379.0,
                    billing_cycle: client_1.BillingCycle.MONTHLY,
                    brand_color: '#000000',
                },
                {
                    name: 'GitHub Copilot',
                    category: 'Development',
                    price: 350.0,
                    billing_cycle: client_1.BillingCycle.MONTHLY,
                    brand_color: '#24292E',
                },
            ],
        },
        {
            card_nickname: 'BBL Be1st Smart',
            card_brand: 'Mastercard',
            card_type: client_1.CardType.DEBIT,
            last_4_digits: '7777',
            bank_name: 'Bangkok Bank',
            balance: 8500.0,
            currency: 'THB',
            subscriptions: [
                {
                    name: 'YouTube Premium',
                    category: 'Streaming',
                    price: 179.0,
                    billing_cycle: client_1.BillingCycle.MONTHLY,
                    brand_color: '#FF0000',
                },
                {
                    name: 'iCloud+ 200GB',
                    category: 'Cloud',
                    price: 99.0,
                    billing_cycle: client_1.BillingCycle.MONTHLY,
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
        }
        else {
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
//# sourceMappingURL=seed.js.map