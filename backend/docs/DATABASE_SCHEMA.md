# Database Schema (Current)

This backend uses SQLite (`sql.js`) persisted to `backend/data/schemes.sqlite`.

Migrations are applied from:
- `backend/src/infrastructure/db/migrations/001_init.sql`
- `backend/src/infrastructure/db/migrations/002_normalized_scheme_schema.sql`

## Core Tables

### `schemes_v2`
Primary scheme records.

Columns:
- `id` TEXT PRIMARY KEY
- `name` TEXT NOT NULL
- `description` TEXT NOT NULL
- `ministry` TEXT
- `category` TEXT
- `subcategory` TEXT
- `application_link` TEXT
- `official_source` TEXT
- `target_beneficiaries` TEXT NOT NULL (JSON array)
- `states` TEXT NOT NULL (JSON array)
- `tags_text` TEXT NOT NULL (JSON array)
- `last_updated` TEXT NOT NULL
- `created_at` TEXT NOT NULL
- `updated_at` TEXT NOT NULL

Indexes:
- `idx_schemes_v2_category`
- `idx_schemes_v2_ministry`
- `idx_schemes_v2_subcategory`
- `idx_schemes_v2_last_updated`

### `benefits`
Benefit entries for each scheme.

Columns:
- `id` INTEGER PRIMARY KEY AUTOINCREMENT
- `scheme_id` TEXT NOT NULL
- `benefit_type` TEXT
- `benefit_description` TEXT NOT NULL
- `amount` TEXT

Index:
- `idx_benefits_scheme`

### `eligibility_rules`
Eligibility constraints and profile matching fields.

Columns:
- `id` INTEGER PRIMARY KEY AUTOINCREMENT
- `scheme_id` TEXT NOT NULL
- `gender` TEXT
- `age_min` INTEGER
- `age_max` INTEGER
- `income_limit` INTEGER
- `state` TEXT
- `occupation` TEXT
- `caste_category` TEXT

Indexes:
- `idx_eligibility_scheme`
- `idx_eligibility_state`
- `idx_eligibility_income`

### `documents`
Required documents for scheme applications.

Columns:
- `id` INTEGER PRIMARY KEY AUTOINCREMENT
- `scheme_id` TEXT NOT NULL
- `document_name` TEXT NOT NULL

Index:
- `idx_documents_scheme`

### `tags`
Distinct tag dictionary.

Columns:
- `id` INTEGER PRIMARY KEY AUTOINCREMENT
- `tag_name` TEXT NOT NULL UNIQUE

### `scheme_tags`
Many-to-many join between schemes and tags.

Columns:
- `scheme_id` TEXT NOT NULL
- `tag_id` INTEGER NOT NULL
- PRIMARY KEY (`scheme_id`, `tag_id`)

Indexes:
- `idx_scheme_tags_scheme`
- `idx_scheme_tags_tag`

### `schemes_search_v2`
Precomputed lowercased search text per scheme.

Columns:
- `scheme_id` TEXT PRIMARY KEY
- `search_text` TEXT NOT NULL

Index:
- `idx_schemes_search_v2_text`

## Migration and Ingestion Metadata

### `schema_migrations`
Tracks applied SQL migration files.

Columns:
- `version` TEXT PRIMARY KEY
- `applied_at` TEXT NOT NULL

### `ingestion_runs`
Tracks each ingestion run summary.

Columns:
- `run_id` TEXT PRIMARY KEY
- `source_path` TEXT NOT NULL
- `imported_count` INTEGER NOT NULL
- `duplicate_count` INTEGER NOT NULL
- `validation_errors` TEXT NOT NULL (JSON array)
- `created_at` TEXT NOT NULL
