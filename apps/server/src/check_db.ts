import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const users = await prisma.user.findMany({
    select: {
      id: true,
      email: true,
      role: true,
      monthly_income: true,
      payment_cards: {
        include: {
          subscriptions: true,
        },
      },
      subscriptions: true,
    },
  });

  for (const u of users) {
    console.log(`\n=== USER: ${u.email} (${u.id}) ===`);
    console.log(`Monthly Income: ${u.monthly_income?.toString() ?? 'N/A'}`);
    console.log(`Payment Cards (${u.payment_cards.length}):`);
    for (const c of u.payment_cards) {
      console.log(
        `  - Card: ${c.bank_name} •••• ${c.last_4_digits} | Active: ${c.is_active} | Balance: ${c.balance.toString()} | Subscriptions on card: ${c.subscriptions.length}`,
      );
    }
    console.log(`User Subscriptions (${u.subscriptions.length}):`);
    for (const s of u.subscriptions) {
      console.log(
        `  - Sub: ${s.name} | Status: ${s.status} | Usage: ${s.usage_status} | Card: ${s.payment_card_id} | Price: ${s.price.toString()}`,
      );
    }
  }
  const tt = await prisma.user.findUnique({
    where: { email: 'tt@gmail.com' },
  });
  if (tt) {
    const mockCards = await prisma.mockBankCard.findMany({
      include: { subscriptions: true },
    });
    console.log('\n=== MOCK BANK CARDS ===');
    for (const mc of mockCards) {
      console.log(
        `Mock: ${mc.bank_name} (${mc.last_4_digits}) id=${mc.id} balance=${mc.balance.toString()} subs=${mc.subscriptions.length}`,
      );
      for (const s of mc.subscriptions) {
        console.log(
          `   - ${s.name} (${s.price.toString()}) ${s.billing_cycle}`,
        );
      }
    }
  }
}

void main().finally(() => prisma.$disconnect());
