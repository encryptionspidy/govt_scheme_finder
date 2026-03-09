CREATE TABLE IF NOT EXISTS schemes (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  benefits TEXT NOT NULL,
  eligibility TEXT NOT NULL,
  states TEXT NOT NULL,
  income_limit INTEGER,
  gender TEXT,
  age_min INTEGER,
  age_max INTEGER,
  application_link TEXT,
  source TEXT NOT NULL,
  last_updated TEXT NOT NULL,
  metadata TEXT NOT NULL DEFAULT '{}',
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_schemes_category ON schemes(category);
CREATE INDEX IF NOT EXISTS idx_schemes_gender ON schemes(gender);
CREATE INDEX IF NOT EXISTS idx_schemes_income_limit ON schemes(income_limit);
CREATE INDEX IF NOT EXISTS idx_schemes_age_min ON schemes(age_min);
CREATE INDEX IF NOT EXISTS idx_schemes_age_max ON schemes(age_max);
CREATE INDEX IF NOT EXISTS idx_schemes_last_updated ON schemes(last_updated);

CREATE TABLE IF NOT EXISTS ingestion_runs (
  run_id TEXT PRIMARY KEY,
  source_path TEXT NOT NULL,
  imported_count INTEGER NOT NULL,
  duplicate_count INTEGER NOT NULL,
  validation_errors TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS schemes_search (
  id TEXT PRIMARY KEY,
  title_text TEXT NOT NULL,
  description_text TEXT NOT NULL,
  benefits_text TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_schemes_search_title ON schemes_search(title_text);
CREATE INDEX IF NOT EXISTS idx_schemes_search_description ON schemes_search(description_text);
