# SchemePlus

SchemePlus is a full-stack government-scheme discovery platform prototype.
It combines:
- A Flutter mobile/web client for search, recommendations, and multilingual UX.
- A Node.js backend API with a SQLite data layer, ingestion pipeline, validation, and recommendation scoring.

The project is designed for local-first development and can be extended to production deployments.

## Project Purpose

SchemePlus helps users discover relevant Indian government schemes by:
- Searching and filtering scheme catalogs.
- Matching scheme eligibility against user profiles.
- Supporting bilingual content (English/Tamil) in the app.
- Providing quick navigation to apply links and notifications.

## Architecture

### High-level Components
- `frontend/`: Flutter app (Provider + Hive + HTTP client).
- `backend/`: Express API (versioned routes, modules, validation, caching, metrics, ingestion scripts).

### Backend Runtime Layers
- API layer: Express routes under `/api/v1` (also mounted on `/api` for compatibility).
- Module layer: `schemes`, `notifications`, `health`.
- Service layer: filtering, recommendation scoring, cache wrapping.
- Repository layer: SQLite reads/writes and entity hydration.
- Infrastructure layer: DB migration runner, cache, metrics, middleware, logging.

## Folder Structure

```text
.
├── backend/
│   ├── data/
│   │   └── sample_schemes.json
│   ├── docs/
│   │   ├── ARCHITECTURE_PROPOSAL.md
│   │   └── DATABASE_SCHEMA.md
│   ├── scripts/
│   │   ├── init_db.js
│   │   ├── ingest_schemes.js
│   │   ├── myscheme_crawler.js
│   │   ├── import_public_dataset.js
│   │   ├── update_scheme_data.js
│   │   └── data_quality_audit.js
│   ├── src/
│   │   ├── app/
│   │   ├── config/
│   │   ├── core/
│   │   ├── infrastructure/
│   │   │   └── db/migrations/
│   │   └── modules/
│   ├── openapi.yaml
│   ├── package.json
│   └── Dockerfile
├── frontend/
│   ├── assets/
│   │   └── translations/
│   ├── lib/
│   │   ├── data/
│   │   ├── providers/
│   │   ├── screens/
│   │   ├── theme/
│   │   └── utils/
│   └── pubspec.yaml
├── QUICK_START.md
├── FIXES_APPLIED.md
├── NAVIGATION_IMPROVEMENTS.md
└── README.md
```

## Prerequisites

### Required
- Node.js 20+ (tested with Node 25 in current workspace).
- npm 10+
- Flutter SDK 3.3+ with Dart 3.3+

### Recommended
- Android Studio or VS Code with Flutter/Dart plugins.
- Chrome (for Flutter web runs).

## Installation

### 1. Clone and enter project
```bash
cd govt_scheme_finder
```

### 2. Install backend dependencies
```bash
cd backend
npm install
```

### 3. Install Flutter dependencies
```bash
cd ../frontend
flutter pub get
```

## Environment Configuration

Use `backend/.env.example` as reference.

Create `backend/.env` with at least:
```env
PORT=4000
NODE_ENV=development
LOG_LEVEL=info
DB_PATH=./data/schemes.sqlite
SAMPLE_DATA_PATH=./data/sample_schemes.json
CACHE_TTL_SECONDS=600
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX=120
REQUEST_TIMEOUT_MS=10000
```

Optional ETL/crawler settings are also available in `backend/.env.example`.

## Running the Backend

From `backend/`:

### Development mode
```bash
npm run dev
```

### Production-style run
```bash
npm start
```

If `4000` is already in use, run with another port:
```bash
# PowerShell
$env:PORT=4100
npm start
```

## Running the Flutter App

From `frontend/`:

### Android emulator
```bash
flutter run
```

### Chrome/web
```bash
flutter run -d chrome
```

### Override backend URL
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:4000
```

The app normalizes this value to `/api/v1` automatically.

## Database and Data Pipeline

### Runtime storage
- SQLite DB file: `backend/data/schemes.sqlite`
- Migration runner: `backend/src/infrastructure/db/sqlite.js`
- Migrations:
  - `001_init.sql`
  - `002_normalized_scheme_schema.sql`

### Core data commands
From `backend/`:

```bash
npm run db:init
npm run db:ingest
npm run data:audit
```

### Extended ETL commands
```bash
npm run etl:crawl:myscheme
npm run etl:import:url -- "<dataset-url>"
npm run etl:update
```

`etl:update` orchestrates crawl/import/merge/ingest/audit in one flow.

## API Endpoints Overview

Base URL: `http://localhost:4000/api/v1`

### Health and diagnostics
- `GET /health`
- `GET /metrics`
- `GET /test/ping`

### Schemes
- `GET /schemes`
- `GET /schemes/search`
- `GET /schemes/categories`
- `GET /schemes/ministries`
- `GET /schemes/beneficiary-types`
- `GET /schemes/category/:category`
- `GET /schemes/state/:state`
- `GET /schemes/:id`
- `POST /schemes/recommendations`

### Notifications
- `GET /notifications`
- `POST /notifications/simulate`
- `POST /notifications/mark-read/:id`

API docs UI:
- `http://localhost:4000/docs`

## Development Workflow

### Typical backend loop
1. `cd backend`
2. `npm install` (first time only)
3. `npm run db:init`
4. `npm run db:ingest`
5. `npm run dev`
6. `npm run lint`

### Typical frontend loop
1. `cd frontend`
2. `flutter pub get`
3. `flutter run`
4. `flutter analyze`

### Working with fresh data
1. Configure ETL env vars in `backend/.env`
2. Run `npm run etl:update`
3. Restart backend
4. Refresh app

## Notes for Contributors

- Legacy backend folders (`backend/src/routes`, `backend/src/repositories`, etc.) exist, but active runtime entrypoint is `backend/src/server.js` with `backend/src/app/createApp.js` and `backend/src/modules/*`.
- Keep generated and local-only files out of git (`node_modules`, `.env`, Flutter generated metadata, build artifacts).
- Prefer adding docs for architectural changes in `backend/docs/` and keep this README as the main onboarding guide.

## Additional Documentation

- `QUICK_START.md`: quick manual checks.
- `FIXES_APPLIED.md`: historical bug-fix notes.
- `NAVIGATION_IMPROVEMENTS.md`: UI navigation refactor notes.
- `backend/docs/ARCHITECTURE_PROPOSAL.md`: backend architecture direction.
- `backend/docs/DATABASE_SCHEMA.md`: schema reference.
