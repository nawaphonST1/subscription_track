-- CreateEnum
CREATE TYPE "DevicePlatform" AS ENUM ('ANDROID', 'IOS');

-- CreateEnum
CREATE TYPE "DeviceRegistrationStatus" AS ENUM ('ACTIVE', 'REVOKED', 'INVALID');

-- CreateTable
CREATE TABLE "device_registrations" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "push_token" TEXT NOT NULL,
    "platform" "DevicePlatform" NOT NULL,
    "status" "DeviceRegistrationStatus" NOT NULL DEFAULT 'ACTIVE',
    "deactivated_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "device_registrations_pkey" PRIMARY KEY ("id")
);

-- Add row-local lifecycle and token integrity constraints.
ALTER TABLE "device_registrations"
ADD CONSTRAINT "ck_device_registrations_push_token_nonblank"
CHECK (char_length(btrim("push_token")) > 0);

ALTER TABLE "device_registrations"
ADD CONSTRAINT "ck_device_registrations_deactivation_state"
CHECK (
    (
        "status" = 'ACTIVE'
        AND "deactivated_at" IS NULL
    )
    OR
    (
        "status" IN ('REVOKED', 'INVALID')
        AND "deactivated_at" IS NOT NULL
    )
);

-- CreateIndex
CREATE INDEX "device_registrations_user_id_status_idx" ON "device_registrations"("user_id", "status");

-- CreateIndex
CREATE INDEX "device_registrations_push_token_idx" ON "device_registrations"("push_token");

-- CreateIndex (Partial unique constraint for active push token)
CREATE UNIQUE INDEX "uq_device_registrations_active_token" ON "device_registrations"("push_token") WHERE status = 'ACTIVE';

-- AddForeignKey
ALTER TABLE "device_registrations" ADD CONSTRAINT "device_registrations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
