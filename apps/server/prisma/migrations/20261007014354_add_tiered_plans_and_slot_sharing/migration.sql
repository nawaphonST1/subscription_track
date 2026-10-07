-- CreateEnum safely if not exists
DO $$ BEGIN
    CREATE TYPE "UserRole" AS ENUM ('USER', 'ADMIN');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- AlterTable
ALTER TABLE "subscription_presets" ADD COLUMN IF NOT EXISTS "available_plans" JSONB,
ADD COLUMN IF NOT EXISTS "features" TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN IF NOT EXISTS "max_slots" INTEGER NOT NULL DEFAULT 1;

-- AlterTable
ALTER TABLE "user_subscriptions" ADD COLUMN IF NOT EXISTS "plan_tier" TEXT,
ADD COLUMN IF NOT EXISTS "price_per_slot" DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS "shared_members" INTEGER NOT NULL DEFAULT 1;

-- AlterTable
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "role" "UserRole" NOT NULL DEFAULT 'USER';

