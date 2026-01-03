-- Schema for Mediswitch Interactions Database (mediswitch-interactions)
-- Split from main DB to handle large dataset size (1GB+)

-- 1. Drug Interactions (Rules) Table
CREATE TABLE IF NOT EXISTS drug_interactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ingredient1 TEXT,
  ingredient2 TEXT,
  severity TEXT,
  effect TEXT,
  source TEXT,
  management_text TEXT,
  mechanism_text TEXT,
  recommendation TEXT,
  risk_level TEXT,
  type TEXT,
  metabolism_info TEXT,
  source_url TEXT,
  reference_text TEXT,
  alternatives_a TEXT,
  alternatives_b TEXT,
  updated_at INTEGER DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_rules_pair ON drug_interactions(ingredient1, ingredient2);
CREATE INDEX IF NOT EXISTS idx_rules_i1 ON drug_interactions(ingredient1);
CREATE INDEX IF NOT EXISTS idx_rules_i2 ON drug_interactions(ingredient2);

-- 2. Food Interactions Table
CREATE TABLE IF NOT EXISTS food_interactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  med_id INTEGER,
  trade_name TEXT,
  interaction TEXT NOT NULL,
  ingredient TEXT,
  severity TEXT,
  management_text TEXT,
  mechanism_text TEXT,
  reference_text TEXT,
  source TEXT DEFAULT 'DrugBank',
  created_at INTEGER DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_food_med_id ON food_interactions(med_id);

-- 3. Disease Interactions Table
CREATE TABLE IF NOT EXISTS disease_interactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  med_id INTEGER,
  trade_name TEXT,
  disease_name TEXT NOT NULL,
  interaction_text TEXT NOT NULL,
  severity TEXT,
  reference_text TEXT,
  source TEXT DEFAULT 'DDInter',
  created_at INTEGER DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_disease_med_id ON disease_interactions(med_id);
