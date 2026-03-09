CREATE TABLE IF NOT EXISTS schemes_v2 (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  ministry TEXT,
  category TEXT,
  subcategory TEXT,
  application_link TEXT,
  official_source TEXT,
  target_beneficiaries TEXT NOT NULL DEFAULT '[]',
  states TEXT NOT NULL DEFAULT '[]',
  tags_text TEXT NOT NULL DEFAULT '[]',
  last_updated TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_schemes_v2_category ON schemes_v2(category);
CREATE INDEX IF NOT EXISTS idx_schemes_v2_ministry ON schemes_v2(ministry);
CREATE INDEX IF NOT EXISTS idx_schemes_v2_subcategory ON schemes_v2(subcategory);
CREATE INDEX IF NOT EXISTS idx_schemes_v2_last_updated ON schemes_v2(last_updated);

CREATE TABLE IF NOT EXISTS benefits (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  scheme_id TEXT NOT NULL,
  benefit_type TEXT,
  benefit_description TEXT NOT NULL,
  amount TEXT,
  FOREIGN KEY (scheme_id) REFERENCES schemes_v2(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_benefits_scheme ON benefits(scheme_id);

CREATE TABLE IF NOT EXISTS eligibility_rules (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  scheme_id TEXT NOT NULL,
  gender TEXT,
  age_min INTEGER,
  age_max INTEGER,
  income_limit INTEGER,
  state TEXT,
  occupation TEXT,
  caste_category TEXT,
  FOREIGN KEY (scheme_id) REFERENCES schemes_v2(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_eligibility_scheme ON eligibility_rules(scheme_id);
CREATE INDEX IF NOT EXISTS idx_eligibility_state ON eligibility_rules(state);
CREATE INDEX IF NOT EXISTS idx_eligibility_income ON eligibility_rules(income_limit);

CREATE TABLE IF NOT EXISTS documents (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  scheme_id TEXT NOT NULL,
  document_name TEXT NOT NULL,
  FOREIGN KEY (scheme_id) REFERENCES schemes_v2(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_documents_scheme ON documents(scheme_id);

CREATE TABLE IF NOT EXISTS tags (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tag_name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS scheme_tags (
  scheme_id TEXT NOT NULL,
  tag_id INTEGER NOT NULL,
  PRIMARY KEY (scheme_id, tag_id),
  FOREIGN KEY (scheme_id) REFERENCES schemes_v2(id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_scheme_tags_scheme ON scheme_tags(scheme_id);
CREATE INDEX IF NOT EXISTS idx_scheme_tags_tag ON scheme_tags(tag_id);

CREATE TABLE IF NOT EXISTS schemes_search_v2 (
  scheme_id TEXT PRIMARY KEY,
  search_text TEXT NOT NULL,
  FOREIGN KEY (scheme_id) REFERENCES schemes_v2(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_schemes_search_v2_text ON schemes_search_v2(search_text);
