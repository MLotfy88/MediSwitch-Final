-- Cloudflare D1 Schema for Drug Interactions
-- This table stores drug-drug interaction data synced from OpenFDA

CREATE TABLE IF NOT EXISTS drug_interactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ingredient1 TEXT NOT NULL,
  ingredient2 TEXT NOT NULL,
  severity TEXT NOT NULL CHECK(severity IN ('contraindicated', 'severe', 'major', 'moderate', 'minor', 'unknown')),
  type TEXT NOT NULL CHECK(type IN ('pharmacodynamic', 'pharmacokinetic', 'unknown')),
  effect TEXT NOT NULL,
  arabic_effect TEXT DEFAULT '',
  recommendation TEXT DEFAULT '',
  arabic_recommendation TEXT DEFAULT '',
  source TEXT DEFAULT 'OpenFDA',
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_interactions_ingredient1 ON drug_interactions(ingredient1);
CREATE INDEX IF NOT EXISTS idx_interactions_ingredient2 ON drug_interactions(ingredient2);
CREATE INDEX IF NOT EXISTS idx_interactions_severity ON drug_interactions(severity);
CREATE INDEX IF NOT EXISTS idx_interactions_type ON drug_interactions(type);

-- Compound index for pair lookups
CREATE INDEX IF NOT EXISTS idx_interactions_pair ON drug_interactions(ingredient1, ingredient2);

-- Metadata table for tracking updates
CREATE TABLE IF NOT EXISTS interaction_sync_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sync_date DATETIME NOT NULL,
  total_interactions INTEGER NOT NULL,
  unique_interactions INTEGER NOT NULL,
  openfda_files_processed INTEGER NOT NULL,
  status TEXT NOT NULL CHECK(status IN ('success', 'failed', 'partial')),
  error_message TEXT,
  duration_seconds INTEGER,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
