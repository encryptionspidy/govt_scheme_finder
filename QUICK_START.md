# Quick Start

## 1. Backend

```bash
cd backend
npm install
npm run db:init
npm run db:ingest
npm run dev
```

Backend default URL:
- `http://localhost:4000/api/v1`

If port `4000` is busy:
```powershell
$env:PORT=4100
npm start
```

## 2. Flutter App

```bash
cd frontend
flutter pub get
flutter run
```

Optional explicit API URL:
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:4000
```

## 3. Smoke Test Endpoints

- `GET /api/v1/health`
- `GET /api/v1/schemes?limit=2`
- `GET /api/v1/schemes/search?q=farmer&limit=2`
- `GET /api/v1/schemes/categories`
- `GET /api/v1/schemes/ministries`
- `GET /api/v1/schemes/beneficiary-types`

Swagger UI:
- `http://localhost:4000/docs`

## 4. Data Pipeline Refresh

```bash
cd backend
npm run etl:update
```

This runs crawl/import/merge/ingest/audit and updates the local SQLite data.

## 5. Quality Checks

```bash
cd backend
npm run lint

cd ../frontend
flutter analyze
```
