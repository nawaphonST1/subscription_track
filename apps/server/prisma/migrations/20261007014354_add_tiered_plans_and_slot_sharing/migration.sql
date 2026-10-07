-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('USER', 'ADMIN');

-- AlterTable
ALTER TABLE "subscription_presets" ADD COLUMN     "available_plans" JSONB,
ADD COLUMN     "features" TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN     "max_slots" INTEGER NOT NULL DEFAULT 1;

-- AlterTable
ALTER TABLE "user_subscriptions" ADD COLUMN     "plan_tier" TEXT,
ADD COLUMN     "price_per_slot" DECIMAL(10,2),
ADD COLUMN     "shared_members" INTEGER NOT NULL DEFAULT 1;

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "role" "UserRole" NOT NULL DEFAULT 'USER';
