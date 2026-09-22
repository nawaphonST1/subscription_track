-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "CardType" AS ENUM ('DEBIT', 'CREDIT');

-- CreateEnum
CREATE TYPE "BillingCycle" AS ENUM ('MONTHLY', 'YEARLY', 'WEEKLY');

-- CreateEnum
CREATE TYPE "UsageStatus" AS ENUM ('FREQUENT', 'OCCASIONAL', 'UNUSED');

-- CreateEnum
CREATE TYPE "SubscriptionStatus" AS ENUM ('ACTIVE', 'CANCELLED', 'PAUSED');

-- CreateEnum
CREATE TYPE "NotificationType" AS ENUM ('RENEWAL_ALERT', 'UNUSED_SUBSCRIPTION_WARNING', 'SECURITY_ALERT');

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "name" TEXT,
    "monthly_income" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "security_pin_hash" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "payment_cards" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "card_nickname" TEXT NOT NULL,
    "card_brand" TEXT NOT NULL,
    "card_type" "CardType" NOT NULL DEFAULT 'DEBIT',
    "last_4_digits" VARCHAR(4) NOT NULL,
    "bank_name" TEXT NOT NULL,
    "balance" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "currency" VARCHAR(3) NOT NULL DEFAULT 'THB',
    "is_default" BOOLEAN NOT NULL DEFAULT false,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "payment_cards_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "subscription_presets" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "default_price" DECIMAL(10,2) NOT NULL,
    "billing_cycle" "BillingCycle" NOT NULL DEFAULT 'MONTHLY',
    "brand_color" TEXT NOT NULL,
    "icon_url" TEXT,
    "description" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "subscription_presets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "mock_bank_cards" (
    "id" TEXT NOT NULL,
    "card_nickname" TEXT NOT NULL,
    "card_brand" TEXT NOT NULL,
    "card_type" "CardType" NOT NULL DEFAULT 'DEBIT',
    "last_4_digits" VARCHAR(4) NOT NULL,
    "bank_name" TEXT NOT NULL,
    "balance" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "currency" VARCHAR(3) NOT NULL DEFAULT 'THB',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "mock_bank_cards_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "mock_bank_card_subscriptions" (
    "id" TEXT NOT NULL,
    "mock_bank_card_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "price" DECIMAL(10,2) NOT NULL,
    "billing_cycle" "BillingCycle" NOT NULL DEFAULT 'MONTHLY',
    "brand_color" TEXT,

    CONSTRAINT "mock_bank_card_subscriptions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_subscriptions" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "payment_card_id" TEXT NOT NULL,
    "preset_id" TEXT,
    "name" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "price" DECIMAL(10,2) NOT NULL,
    "billing_cycle" "BillingCycle" NOT NULL DEFAULT 'MONTHLY',
    "start_date" TIMESTAMP(3) NOT NULL,
    "next_renewal_date" TIMESTAMP(3) NOT NULL,
    "usage_status" "UsageStatus" NOT NULL DEFAULT 'FREQUENT',
    "status" "SubscriptionStatus" NOT NULL DEFAULT 'ACTIVE',
    "brand_color" TEXT,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_subscriptions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "savings_cancellation_logs" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "subscription_id" TEXT,
    "subscription_name" TEXT NOT NULL,
    "monthly_price" DECIMAL(10,2) NOT NULL,
    "yearly_savings_projection" DECIMAL(10,2) NOT NULL,
    "reason" TEXT,
    "cancelled_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "savings_cancellation_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notifications" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "type" "NotificationType" NOT NULL,
    "is_read" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "payment_cards_user_id_idx" ON "payment_cards"("user_id");

-- CreateIndex
CREATE INDEX "payment_cards_user_id_is_active_idx" ON "payment_cards"("user_id", "is_active");

-- CreateIndex
CREATE UNIQUE INDEX "subscription_presets_name_key" ON "subscription_presets"("name");

-- CreateIndex
CREATE INDEX "mock_bank_cards_bank_name_last_4_digits_idx" ON "mock_bank_cards"("bank_name", "last_4_digits");

-- CreateIndex
CREATE INDEX "mock_bank_card_subscriptions_mock_bank_card_id_idx" ON "mock_bank_card_subscriptions"("mock_bank_card_id");

-- CreateIndex
CREATE INDEX "user_subscriptions_user_id_idx" ON "user_subscriptions"("user_id");

-- CreateIndex
CREATE INDEX "user_subscriptions_payment_card_id_idx" ON "user_subscriptions"("payment_card_id");

-- CreateIndex
CREATE INDEX "user_subscriptions_user_id_status_idx" ON "user_subscriptions"("user_id", "status");

-- CreateIndex
CREATE INDEX "user_subscriptions_next_renewal_date_idx" ON "user_subscriptions"("next_renewal_date");

-- CreateIndex
CREATE INDEX "savings_cancellation_logs_user_id_idx" ON "savings_cancellation_logs"("user_id");

-- CreateIndex
CREATE INDEX "savings_cancellation_logs_cancelled_at_idx" ON "savings_cancellation_logs"("cancelled_at");

-- CreateIndex
CREATE INDEX "notifications_user_id_is_read_idx" ON "notifications"("user_id", "is_read");

-- CreateIndex
CREATE INDEX "notifications_created_at_idx" ON "notifications"("created_at");

-- AddForeignKey
ALTER TABLE "payment_cards" ADD CONSTRAINT "payment_cards_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mock_bank_card_subscriptions" ADD CONSTRAINT "mock_bank_card_subscriptions_mock_bank_card_id_fkey" FOREIGN KEY ("mock_bank_card_id") REFERENCES "mock_bank_cards"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_subscriptions" ADD CONSTRAINT "user_subscriptions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_subscriptions" ADD CONSTRAINT "user_subscriptions_payment_card_id_fkey" FOREIGN KEY ("payment_card_id") REFERENCES "payment_cards"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_subscriptions" ADD CONSTRAINT "user_subscriptions_preset_id_fkey" FOREIGN KEY ("preset_id") REFERENCES "subscription_presets"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "savings_cancellation_logs" ADD CONSTRAINT "savings_cancellation_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
