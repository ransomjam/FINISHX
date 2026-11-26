-- CreateEnum
CREATE TYPE "AuthProvider" AS ENUM ('EMAIL', 'GOOGLE', 'APPLE');

-- CreateEnum
CREATE TYPE "JourneyCategory" AS ENUM ('DATA_SCIENCE', 'SOFTWARE_ENGINEERING', 'CYBERSECURITY', 'PRODUCT_MANAGEMENT', 'MARKETING', 'ENTREPRENEURSHIP', 'PERSONAL_DEVELOPMENT', 'LANGUAGES', 'FITNESS', 'OTHER');

-- CreateEnum
CREATE TYPE "ResourceType" AS ENUM ('UDEMY', 'COURSERA', 'YOUTUBE', 'BOOK', 'COACH_OR_MENTOR', 'PERSONAL_STUDY_PLAN', 'OTHER');

-- CreateEnum
CREATE TYPE "JourneyStatus" AS ENUM ('DRAFT', 'QUEUED', 'SCHEDULED', 'ACTIVE', 'PAUSED', 'COMPLETED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "SessionStatus" AS ENUM ('SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'MISSED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "SessionFeeling" AS ENUM ('DIFFICULT', 'OKAY', 'GOOD', 'EXCELLENT');

-- CreateEnum
CREATE TYPE "PauseReason" AS ENUM ('VACATION', 'ILLNESS', 'FAMILY_COMMITMENTS', 'WORK_COMMITMENTS', 'EXAMS', 'OTHER');

-- CreateEnum
CREATE TYPE "WeeklyCompletionAnswer" AS ENUM ('YES', 'PARTIALLY', 'NO');

-- CreateEnum
CREATE TYPE "CompletionOutcome" AS ENUM ('YES', 'PARTIALLY', 'NOT_YET');

-- CreateEnum
CREATE TYPE "ReactionType" AS ENUM ('APPLAUSE', 'FIRE', 'STRENGTH', 'CELEBRATION');

-- CreateEnum
CREATE TYPE "LeagueTier" AS ENUM ('FOUNDATION', 'MOMENTUM', 'RESOLUTE', 'VANGUARD', 'SUMMIT');

-- CreateEnum
CREATE TYPE "GroupRole" AS ENUM ('MEMBER', 'LEADER');

-- CreateEnum
CREATE TYPE "FeedActivityType" AS ENUM ('SESSION_COMPLETED', 'CONSISTENCY_STREAK', 'WEEKLY_COMMITMENT_COMPLETED', 'PROGRESS_SHARED', 'JOURNEY_COMPLETED');

-- CreateEnum
CREATE TYPE "DevicePlatform" AS ENUM ('ANDROID', 'IOS', 'WEB');

-- CreateEnum
CREATE TYPE "SyncEventStatus" AS ENUM ('PROCESSED', 'CONFLICT_SKIPPED', 'REJECTED');

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT,
    "name" TEXT NOT NULL,
    "firstName" TEXT NOT NULL,
    "avatarUrl" TEXT,
    "authProvider" "AuthProvider" NOT NULL DEFAULT 'EMAIL',
    "emailVerified" BOOLEAN NOT NULL DEFAULT false,
    "verificationToken" TEXT,
    "passwordResetToken" TEXT,
    "passwordResetExpires" TIMESTAMP(3),
    "timezone" TEXT NOT NULL DEFAULT 'UTC',
    "lastActiveAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RefreshToken" (
    "id" TEXT NOT NULL,
    "tokenHash" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "deviceId" TEXT,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "revokedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "RefreshToken_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Journey" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "category" "JourneyCategory" NOT NULL,
    "resourceType" "ResourceType" NOT NULL DEFAULT 'OTHER',
    "resourceName" TEXT,
    "resourceUrl" TEXT,
    "status" "JourneyStatus" NOT NULL DEFAULT 'ACTIVE',
    "startDate" TIMESTAMP(3) NOT NULL,
    "targetCompletionDate" TIMESTAMP(3) NOT NULL,
    "originalTargetDate" TIMESTAMP(3) NOT NULL,
    "commitmentSignedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "groupId" TEXT,
    "pauseReason" "PauseReason",
    "pausedAt" TIMESTAMP(3),
    "cancelledAt" TIMESTAMP(3),
    "cancelReason" TEXT,
    "completedAt" TIMESTAMP(3),
    "completionOutcome" "CompletionOutcome",
    "proudAccomplishment" TEXT,
    "biggestLesson" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Journey_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CommitmentSchedule" (
    "id" TEXT NOT NULL,
    "journeyId" TEXT NOT NULL,
    "effectiveFrom" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CommitmentSchedule_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CommitmentDay" (
    "id" TEXT NOT NULL,
    "scheduleId" TEXT NOT NULL,
    "weekday" INTEGER NOT NULL,
    "startHour" INTEGER NOT NULL,
    "startMinute" INTEGER NOT NULL,
    "endHour" INTEGER NOT NULL,
    "endMinute" INTEGER NOT NULL,
    "durationMinutes" INTEGER NOT NULL,

    CONSTRAINT "CommitmentDay_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Session" (
    "id" TEXT NOT NULL,
    "journeyId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "scheduledDate" TIMESTAMP(3) NOT NULL,
    "plannedStartHour" INTEGER NOT NULL,
    "plannedStartMinute" INTEGER NOT NULL,
    "plannedEndHour" INTEGER NOT NULL,
    "plannedEndMinute" INTEGER NOT NULL,
    "plannedDurationMinutes" INTEGER NOT NULL,
    "status" "SessionStatus" NOT NULL DEFAULT 'SCHEDULED',
    "startedAt" TIMESTAMP(3),
    "endedAt" TIMESTAMP(3),
    "actualDurationMinutes" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Session_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SessionReflection" (
    "id" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "journeyId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "feeling" "SessionFeeling" NOT NULL,
    "note" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SessionReflection_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "JourneyUpdate" (
    "id" TEXT NOT NULL,
    "journeyId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "content" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "JourneyUpdate_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AccountabilityGroup" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "category" "JourneyCategory" NOT NULL,
    "league" "LeagueTier" NOT NULL DEFAULT 'FOUNDATION',
    "healthScore" INTEGER NOT NULL DEFAULT 80,
    "maxMembers" INTEGER NOT NULL DEFAULT 20,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "AccountabilityGroup_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "GroupMember" (
    "id" TEXT NOT NULL,
    "groupId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "role" "GroupRole" NOT NULL DEFAULT 'MEMBER',
    "joinedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "GroupMember_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "FeedActivity" (
    "id" TEXT NOT NULL,
    "groupId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "type" "FeedActivityType" NOT NULL,
    "message" TEXT NOT NULL,
    "detailText" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "FeedActivity_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "FeedReaction" (
    "id" TEXT NOT NULL,
    "activityId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "type" "ReactionType" NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "FeedReaction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WeeklyReflection" (
    "id" TEXT NOT NULL,
    "journeyId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "weekStartDate" TIMESTAMP(3) NOT NULL,
    "completedCommitments" "WeeklyCompletionAnswer" NOT NULL,
    "biggestWin" TEXT NOT NULL,
    "biggestChallenge" TEXT NOT NULL,
    "nextWeekFocus" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "WeeklyReflection_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "JourneyPause" (
    "id" TEXT NOT NULL,
    "journeyId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "pausedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "resumedAt" TIMESTAMP(3),
    "reason" "PauseReason" NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "JourneyPause_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "JourneyHistory" (
    "id" TEXT NOT NULL,
    "journeyId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "event" TEXT NOT NULL,
    "metadata" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "JourneyHistory_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Notification" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "actionRoute" TEXT,
    "isRead" BOOLEAN NOT NULL DEFAULT false,
    "readAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Notification_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Device" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "deviceToken" TEXT NOT NULL,
    "platform" "DevicePlatform" NOT NULL DEFAULT 'ANDROID',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Device_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SyncEvent" (
    "id" TEXT NOT NULL,
    "clientEventId" TEXT NOT NULL,
    "deviceId" TEXT,
    "userId" TEXT NOT NULL,
    "eventType" TEXT NOT NULL,
    "entityType" TEXT NOT NULL,
    "entityId" TEXT NOT NULL,
    "clientTimestamp" TIMESTAMP(3) NOT NULL,
    "receivedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "payload" JSONB NOT NULL,
    "status" "SyncEventStatus" NOT NULL DEFAULT 'PROCESSED',
    "error" TEXT,

    CONSTRAINT "SyncEvent_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");
CREATE INDEX "User_email_idx" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "RefreshToken_tokenHash_key" ON "RefreshToken"("tokenHash");
CREATE INDEX "RefreshToken_userId_idx" ON "RefreshToken"("userId");
CREATE INDEX "RefreshToken_tokenHash_idx" ON "RefreshToken"("tokenHash");

-- CreateIndex
CREATE INDEX "Journey_userId_status_idx" ON "Journey"("userId", "status");
CREATE INDEX "Journey_groupId_idx" ON "Journey"("groupId");

-- CreateIndex
CREATE UNIQUE INDEX "CommitmentSchedule_journeyId_key" ON "CommitmentSchedule"("journeyId");
CREATE INDEX "CommitmentSchedule_journeyId_idx" ON "CommitmentSchedule"("journeyId");

-- CreateIndex
CREATE INDEX "CommitmentDay_scheduleId_idx" ON "CommitmentDay"("scheduleId");

-- CreateIndex
CREATE INDEX "Session_journeyId_status_idx" ON "Session"("journeyId", "status");
CREATE INDEX "Session_userId_scheduledDate_idx" ON "Session"("userId", "scheduledDate");

-- CreateIndex
CREATE UNIQUE INDEX "SessionReflection_sessionId_key" ON "SessionReflection"("sessionId");
CREATE INDEX "SessionReflection_journeyId_idx" ON "SessionReflection"("journeyId");
CREATE INDEX "SessionReflection_userId_idx" ON "SessionReflection"("userId");

-- CreateIndex
CREATE INDEX "JourneyUpdate_journeyId_idx" ON "JourneyUpdate"("journeyId");
CREATE INDEX "JourneyUpdate_userId_idx" ON "JourneyUpdate"("userId");

-- CreateIndex
CREATE INDEX "AccountabilityGroup_category_idx" ON "AccountabilityGroup"("category");

-- CreateIndex
CREATE UNIQUE INDEX "GroupMember_groupId_userId_key" ON "GroupMember"("groupId", "userId");
CREATE INDEX "GroupMember_userId_idx" ON "GroupMember"("userId");

-- CreateIndex
CREATE INDEX "FeedActivity_groupId_createdAt_idx" ON "FeedActivity"("groupId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "FeedReaction_activityId_userId_type_key" ON "FeedReaction"("activityId", "userId", "type");
CREATE INDEX "FeedReaction_activityId_idx" ON "FeedReaction"("activityId");

-- CreateIndex
CREATE INDEX "WeeklyReflection_journeyId_idx" ON "WeeklyReflection"("journeyId");
CREATE INDEX "WeeklyReflection_userId_weekStartDate_idx" ON "WeeklyReflection"("userId", "weekStartDate");

-- CreateIndex
CREATE INDEX "JourneyPause_journeyId_idx" ON "JourneyPause"("journeyId");

-- CreateIndex
CREATE INDEX "JourneyHistory_journeyId_idx" ON "JourneyHistory"("journeyId");

-- CreateIndex
CREATE INDEX "Notification_userId_isRead_idx" ON "Notification"("userId", "isRead");

-- CreateIndex
CREATE UNIQUE INDEX "Device_deviceToken_key" ON "Device"("deviceToken");
CREATE INDEX "Device_userId_idx" ON "Device"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "SyncEvent_userId_clientEventId_key" ON "SyncEvent"("userId", "clientEventId");
CREATE INDEX "SyncEvent_userId_receivedAt_idx" ON "SyncEvent"("userId", "receivedAt");

-- AddForeignKey
ALTER TABLE "RefreshToken" ADD CONSTRAINT "RefreshToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Journey" ADD CONSTRAINT "Journey_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Journey" ADD CONSTRAINT "Journey_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "AccountabilityGroup"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CommitmentSchedule" ADD CONSTRAINT "CommitmentSchedule_journeyId_fkey" FOREIGN KEY ("journeyId") REFERENCES "Journey"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CommitmentDay" ADD CONSTRAINT "CommitmentDay_scheduleId_fkey" FOREIGN KEY ("scheduleId") REFERENCES "CommitmentSchedule"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Session" ADD CONSTRAINT "Session_journeyId_fkey" FOREIGN KEY ("journeyId") REFERENCES "Journey"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Session" ADD CONSTRAINT "Session_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SessionReflection" ADD CONSTRAINT "SessionReflection_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "SessionReflection" ADD CONSTRAINT "SessionReflection_journeyId_fkey" FOREIGN KEY ("journeyId") REFERENCES "Journey"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "SessionReflection" ADD CONSTRAINT "SessionReflection_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "JourneyUpdate" ADD CONSTRAINT "JourneyUpdate_journeyId_fkey" FOREIGN KEY ("journeyId") REFERENCES "Journey"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "JourneyUpdate" ADD CONSTRAINT "JourneyUpdate_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GroupMember" ADD CONSTRAINT "GroupMember_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "AccountabilityGroup"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "GroupMember" ADD CONSTRAINT "GroupMember_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "FeedActivity" ADD CONSTRAINT "FeedActivity_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "AccountabilityGroup"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "FeedActivity" ADD CONSTRAINT "FeedActivity_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "FeedReaction" ADD CONSTRAINT "FeedReaction_activityId_fkey" FOREIGN KEY ("activityId") REFERENCES "FeedActivity"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "FeedReaction" ADD CONSTRAINT "FeedReaction_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WeeklyReflection" ADD CONSTRAINT "WeeklyReflection_journeyId_fkey" FOREIGN KEY ("journeyId") REFERENCES "Journey"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "WeeklyReflection" ADD CONSTRAINT "WeeklyReflection_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "JourneyPause" ADD CONSTRAINT "JourneyPause_journeyId_fkey" FOREIGN KEY ("journeyId") REFERENCES "Journey"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "JourneyPause" ADD CONSTRAINT "JourneyPause_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "JourneyHistory" ADD CONSTRAINT "JourneyHistory_journeyId_fkey" FOREIGN KEY ("journeyId") REFERENCES "Journey"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "JourneyHistory" ADD CONSTRAINT "JourneyHistory_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Notification" ADD CONSTRAINT "Notification_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Device" ADD CONSTRAINT "Device_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SyncEvent" ADD CONSTRAINT "SyncEvent_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
