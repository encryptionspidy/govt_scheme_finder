# SchemePlus Production Architecture Proposal

## 1. Architecture Overview

- **API Layer:** Express app with versioned routes `/api/v1`.
- **Controller Layer:** Request parsing and response shaping.
- **Service Layer:** Recommendation scoring, business rules, caching orchestration.
- **Repository Layer:** SQL query composition, filtering, pagination, full-text search.
- **Infrastructure:** SQLite persistence, ingestion scripts, centralized logging, metrics, rate limiting.

## 2. Reliability and Observability

- Structured logs via `pino` and `pino-http`.
- Request IDs propagated through `x-request-id`.
- Request timing logs and Prometheus metrics (`/api/v1/metrics`).
- Centralized error middleware with normalized error payloads.
- Input validation through `zod`.

## 3. Data System

- Runtime reads from SQLite, not directly from `sample_schemes.json`.
- Data ingestion pipeline scripts:
  - `npm run db:init`
  - `npm run db:ingest`
  - `npm run data:audit`
- Full-text-style search index: `schemes_search` table + indexed text columns.
- Indexes for `category`, `gender`, `income_limit`, `age_min`, `age_max`, `last_updated`.

## 4. Recommendation Engine

- Rule-based eligibility matching (age, gender, income, occupation, state).
- Weighted scoring model for ranking.
- ML-ready feature vector included in recommendation payload.
- Recommendation response caching for repeated profile lookups.

## 5. Frontend Integration Recommendations

- Use `/api/v1` endpoints and consume `data` + `pagination` envelopes.
- Implement stale-while-revalidate strategy in Flutter repository.
- Keep last successful response in Hive and refresh in background.
- Add user-facing retry UI with requestId surfaced for support diagnostics.

## 6. Innovation Roadmap

- AI assistant for natural-language scheme discovery.
- Eligibility simulator wizard for "what-if" profile changes.
- Side-by-side scheme comparison with explainable scoring.
- Multilingual scheme summarization and simplified policy explanations.
- Event-driven notifications for deadlines and profile-triggered opportunities.
