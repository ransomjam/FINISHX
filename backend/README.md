# FinishX Backend — Production API & Scheduled Job Runner

Production-ready backend for **FinishX**, a commitment and accountability platform built on the philosophy **One Journey. Full Focus. Finish Anything.**

---

## 1. Architecture & Tech Stack

| Component | Technology | Description |
|---|---|---|
| **Runtime** | Node.js (>= 20.0.0) | High-performance JavaScript runtime |
| **Language** | TypeScript (ES2022) | Strict type safety and maintainability |
| **Framework** | Express.js | Modular REST API service |
| **Database** | PostgreSQL on Neon | Serverless PostgreSQL with connection pooling |
| **ORM** | Prisma ORM 6 / 7 | Type-safe queries with `@prisma/adapter-neon` |
| **Validation** | Zod | Runtime request and environment validation |
| **Authentication** | JWT + Refresh Token Rotation | Secure authentication with Argon2 password hashing |
| **Documentation** | OpenAPI 3.0 / Swagger UI | Interactive docs at `/api/v1/docs` |
| **Push Notifications**| Firebase Cloud Messaging (FCM) | Multicast session reminders & group cheers |
| **Hosting** | Render | Native Node Web Service + Render Cron Job |

---

## 2. Directory Structure

```
backend/
├── prisma/
│   ├── migrations/
│   │   └── 20261126000000_init/
│   │       └── migration.sql      # Production DDL schema migration
│   ├── migration_lock.toml
│   └── schema.prisma              # Complete data model definition
├── src/
│   ├── config/                    # Zod validated configuration
│   ├── database/                  # Neon adapter + Prisma client & health check
│   ├── common/                    # AppError, logger, standard response utils
│   ├── middleware/                # JWT auth, Zod validation, rate limiter, error handler
│   ├── modules/
│   │   ├── auth/                  # Register, Login, Refresh, Google OAuth, Me
│   │   ├── users/                 # Profile, Timezone, Account deletion
│   │   ├── journeys/              # Enforces "One Journey. Full Focus." rule
│   │   ├── commitments/           # Schedules & idempotent session generator
│   │   ├── sessions/              # Upcoming, Start, End, Reflect, Skip
│   │   ├── groups/                # Auto-assignment by category, feed & reactions
│   │   ├── reflections/           # Sunday weekly check-in [Yes, Partially, No]
│   │   ├── updates/               # Journey milestones and notes
│   │   ├── dashboard/             # Consolidated GET /api/v1/dashboard for mobile
│   │   ├── sync/                  # Offline-first batch event sync (/sync/events)
│   │   ├── archive/               # Completed & cancelled journey records
│   │   ├── queue/                 # Queued journey management & promotion
│   │   └── notifications/         # In-app notifications & device FCM registration
│   ├── integrations/
│   │   ├── firebase/              # Firebase Admin FCM service
│   │   └── email/                 # Nodemailer transactional email service
│   ├── jobs/
│   │   ├── runner.ts              # Render Cron Job runner CLI (npm run jobs:run)
│   │   ├── journey-activator.job.ts
│   │   ├── session-generator.job.ts
│   │   ├── missed-sessions.job.ts
│   │   └── reminder-notifications.job.ts
│   ├── docs/                      # Swagger/OpenAPI 3.0 specs
│   ├── app.ts                     # Express app setup, security headers & routes
│   └── server.ts                  # Server entrypoint with 30s graceful shutdown
├── package.json
├── tsconfig.json
└── .env.example
```

---

## 3. Render Deployment (Blueprint Setup)

The repository includes a root `render.yaml` blueprint defining both the **Web Service** and the **Cron Job**.

### Step 1: Create a Neon PostgreSQL Database
1. Go to [Neon Console](https://console.neon.tech) and create a project (e.g., `finishx-prod`).
2. Copy the two connection strings:
   - **Pooled connection string** (ends with `-pooler.region.neon.tech` or includes `?sslmode=require`): Use for `DATABASE_URL`.
   - **Direct connection string** (unpooled connection): Use for `DIRECT_URL` (used for `prisma migrate deploy`).

### Step 2: Connect GitHub Repository to Render
1. Go to [Render Dashboard](https://dashboard.render.com).
2. Click **New +** -> **Blueprint**.
3. Select the repository: `https://github.com/ransomjam/FINISHX.git`.
4. Render will parse `render.yaml` and provision:
   - `finishx-api` (Web Service)
   - `finishx-scheduler` (Cron Job running every 5 minutes: `*/5 * * * *`)

### Step 3: Set Environment Variables on Render
Under `finishx-api` and `finishx-scheduler`, fill in:
- `DATABASE_URL`: Your Neon pooled connection string.
- `DIRECT_URL`: Your Neon unpooled direct connection string.
- `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY` (optional, for push notifications).
- `SMTP_HOST`, `SMTP_USER`, `SMTP_PASSWORD` (optional, for email delivery).

### Step 4: Automatic Deployment & Verification
Render will automatically execute:
1. `npm ci && npm run db:generate && npm run build`
2. `npm run db:migrate:deploy` (Applies all database tables safely before booting)
3. `npm run start:prod` (Binds to `0.0.0.0:10000`)
4. Health check at `GET /health/ready` verifies database connectivity and marks the service **Live**.

---

## 4. API Endpoints Overview

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/health/live` | Liveness probe (process up) |
| `GET` | `/health/ready` | Readiness probe (Neon PostgreSQL connected) |
| `GET` | `/api/v1/docs` | Interactive Swagger API Documentation |
| `POST` | `/api/v1/auth/register` | Register with email and password |
| `POST` | `/api/v1/auth/login` | Login and obtain JWT access + refresh tokens |
| `POST` | `/api/v1/auth/refresh` | Refresh token rotation |
| `POST` | `/api/v1/auth/google` | Google OAuth sign-in |
| `GET` | `/api/v1/dashboard` | Consolidated mobile dashboard payload |
| `GET` | `/api/v1/journeys/active` | Current active journey (One Journey rule) |
| `POST` | `/api/v1/journeys` | Create journey (active or queued) |
| `POST` | `/api/v1/journeys/:id/sign` | Sign commitment and activate journey |
| `POST` | `/api/v1/journeys/:id/pause` | Pause journey |
| `POST` | `/api/v1/journeys/:id/resume` | Resume paused journey |
| `POST` | `/api/v1/sessions/:id/start` | Start scheduled focus session |
| `POST` | `/api/v1/sessions/:id/end` | Complete focus session with duration & reflection |
| `POST` | `/api/v1/reflections` | Submit Sunday weekly check-in |
| `POST` | `/api/v1/sync/events` | Sync offline batch events from mobile client |
| `GET` | `/api/v1/archive` | Historical journey archives & stats |
| `GET` | `/api/v1/queue` | Queued future journeys |
