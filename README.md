# FinishX — One Journey. Full Focus.

**Finish Anything.**

FinishX is a premium commitment and accountability platform designed to help people consistently engage with their learning resources, honour their commitments, and finish meaningful personal and professional journeys.

---

## 1. System Architecture

```
FinishX Mobile Application (Flutter)
        │
        ▼ HTTPS / REST API (/api/v1)
Render Web Service: finishx-api (Express.js / TypeScript)
        │
        ▼ Prisma ORM (with @prisma/adapter-neon)
Neon Serverless PostgreSQL (Database)
        ▲
        │ Background cron queries & reminders
Render Cron Job: finishx-scheduler (Runner every 5 mins)
        │
        ▼ Push Notifications
Firebase Cloud Messaging (FCM)
```

---

## 2. Technology Stack

### Mobile Application (Flutter)
- **Framework:** Flutter 3.x (Material 3 with heavy FinishX custom design system)
- **State Management:** Flutter Riverpod 2.6
- **Navigation:** GoRouter 14.6
- **Typography:** Bundled local `Manrope` (headings) and `Inter` (body) variable fonts
- **Offline First:** Local persistence via `SharedPreferences` with honest sync queue
- **Remote Sync:** `HttpRemoteSyncDataSource` communicating with `finishx-api`

### Backend Service (Express.js & Node.js)
- **Runtime:** Node.js (>= 20.0.0) with TypeScript (ES2022)
- **Framework:** Express.js 4.x
- **Database:** PostgreSQL on Neon (Serverless with connection pooling)
- **ORM:** Prisma ORM with `@prisma/adapter-neon`
- **Validation:** Zod 3.x
- **Authentication:** JWT + Refresh Token Rotation with Argon2 password hashing
- **Documentation:** Interactive OpenAPI / Swagger UI at `/api/v1/docs`
- **Cloud Infrastructure:** Render Blueprint (`render.yaml`)

---

## 3. Brand & Visual Design System

- **Primary Colors:** Forest Ink (`#153B35`), Deep Spruce (`#285B50`), Kinetic Mint (`#72E3B6`), Warm Chalk (`#F4F2E9`), Pure Surface (`#FFFFFF`), Soft Sage (`#DCE6DE`), Carbon (`#202A27`), Muted Brick (`#B96C61`).
- **Logo:** Custom vector-drawn `FX` mark depicting two intersecting paths converging toward a shared Kinetic Mint completion endpoint.
- **Philosophy:** **One Journey. Full Focus.** Only one journey can be active at a time; subsequent journeys stay in the Journey Queue until completed or intentionally replaced.

---

## 4. Render Deployment (Blueprint Setup)

The repository includes a root `render.yaml` blueprint defining both the **Web Service** and the **Cron Job**.

### Step 1: Create a Neon PostgreSQL Database
1. Go to [Neon Console](https://console.neon.tech) and create a project (`finishx-prod`).
2. Copy the two connection strings:
   - **Pooled connection string** (ends with `-pooler.region.neon.tech` or includes `?sslmode=require`): Use for `DATABASE_URL`.
   - **Direct connection string** (unpooled connection): Use for `DIRECT_URL` (used for `prisma migrate deploy`).

### Step 2: Deploy to Render via Blueprint
1. Go to [Render Dashboard](https://dashboard.render.com).
2. Click **New +** -> **Blueprint**.
3. Connect repository: `https://github.com/ransomjam/FINISHX.git`.
4. Render automatically configures:
   - `finishx-api` (Web Service, `rootDir: backend`, `npm run start:prod`, health check: `/health/ready`)
   - `finishx-scheduler` (Cron Job, runs every 5 minutes: `npm run jobs:run`)
5. In the Render environment configuration, enter your `DATABASE_URL` and `DIRECT_URL`.
6. Click **Apply**. Render will run `npm run db:migrate:deploy` to apply the database schema, start the server, and mark the deployment **Live**.

---

## 5. Running the Application

### Mobile Client (Flutter)
```bash
# Analyze Flutter code (0 issues)
flutter analyze --no-pub

# Run all 11 unit & widget tests
flutter test --no-pub

# Run on connected Pixel 3 XL device
flutter run -d 89GY0703F
```

### Backend (Local Development)
```bash
cd backend

# Install dependencies
npm install

# Run database migrations
npm run db:migrate:deploy

# Start development server with live reload
npm run dev

# Run scheduled jobs runner
npm run jobs:run
```

---

## 6. Repository Structure

```
finishx/
├── backend/
│   ├── prisma/
│   │   ├── migrations/
│   │   │   └── 20261126000000_init/
│   │   │       └── migration.sql
│   │   └── schema.prisma
│   ├── src/
│   │   ├── config/
│   │   ├── database/
│   │   ├── common/
│   │   ├── middleware/
│   │   ├── modules/
│   │   │   ├── auth/
│   │   │   ├── users/
│   │   │   ├── journeys/
│   │   │   ├── commitments/
│   │   │   ├── sessions/
│   │   │   ├── groups/
│   │   │   ├── reflections/
│   │   │   ├── updates/
│   │   │   ├── dashboard/
│   │   │   ├── sync/
│   │   │   ├── archive/
│   │   │   ├── queue/
│   │   │   └── notifications/
│   │   ├── integrations/
│   │   ├── jobs/
│   │   ├── docs/
│   │   ├── app.ts
│   │   └── server.ts
│   ├── package.json
│   └── tsconfig.json
│
├── lib/                             # Flutter mobile application
│   ├── application/
│   ├── core/
│   ├── data/
│   ├── domain/
│   └── features/
│
├── render.yaml                      # Root Render Blueprint specification
├── pubspec.yaml
└── README.md
```
