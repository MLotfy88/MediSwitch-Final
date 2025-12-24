-- Consolidated Schema for Remaining Missing Tables
-- MediSwitch Advanced Functionality

-- 1. Interactions System
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

CREATE INDEX IF NOT EXISTS idx_interactions_ingredient1 ON drug_interactions(ingredient1);
CREATE INDEX IF NOT EXISTS idx_interactions_ingredient2 ON drug_interactions(ingredient2);
CREATE INDEX IF NOT EXISTS idx_interactions_pair ON drug_interactions(ingredient1, ingredient2);

CREATE TABLE IF NOT EXISTS food_interactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  med_id INTEGER,
  trade_name TEXT,
  interaction TEXT NOT NULL,
  source TEXT DEFAULT 'DrugBank',
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_food_interactions_med ON food_interactions(med_id);
CREATE INDEX IF NOT EXISTS idx_food_interactions_name ON food_interactions(trade_name);

CREATE TABLE IF NOT EXISTS interaction_sync_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sync_date DATETIME NOT NULL,
  total_interactions INTEGER NOT NULL,
  status TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 2. Ingredients Mapping
CREATE TABLE IF NOT EXISTS med_ingredients (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  med_id INTEGER NOT NULL,
  ingredient TEXT NOT NULL,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_med_ingredients_med ON med_ingredients(med_id);
CREATE INDEX IF NOT EXISTS idx_med_ingredients_ing ON med_ingredients(ingredient);

-- 3. Analytics System
CREATE TABLE IF NOT EXISTS analytics_daily (
  date TEXT PRIMARY KEY,            -- YYYY-MM-DD
  total_searches INTEGER DEFAULT 0,
  successful_searches INTEGER DEFAULT 0,
  missed_searches INTEGER DEFAULT 0,
  price_updates INTEGER DEFAULT 0,
  new_drugs INTEGER DEFAULT 0,
  ad_impressions INTEGER DEFAULT 0,
  ad_clicks INTEGER DEFAULT 0,
  ad_revenue REAL DEFAULT 0.0,
  subscription_revenue REAL DEFAULT 0.0,
  active_users INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS drug_views (
  drug_id TEXT PRIMARY KEY,
  view_count INTEGER DEFAULT 1,
  last_viewed_at INTEGER
);

CREATE TABLE IF NOT EXISTS missed_searches (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  query TEXT NOT NULL,
  count INTEGER DEFAULT 1,
  last_seen_at INTEGER,
  created_at INTEGER
);

CREATE INDEX IF NOT EXISTS idx_missed_searches_query ON missed_searches(query);

-- 4. Configuration & App Logic
CREATE TABLE IF NOT EXISTS app_config (
  key TEXT PRIMARY KEY,
  value TEXT,
  description TEXT,
  updated_at INTEGER
);

-- 5. User Behavioral Tables
CREATE TABLE IF NOT EXISTS user_activity (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  drug_id TEXT,
  metadata TEXT,
  created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS user_favorites (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  drug_id TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  UNIQUE(user_id, drug_id)
);

CREATE TABLE IF NOT EXISTS user_search_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  query TEXT NOT NULL,
  results_count INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL
);

-- 6. Monetization Advanced
CREATE TABLE IF NOT EXISTS iap_purchases (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  product_id TEXT NOT NULL,
  transaction_id TEXT UNIQUE NOT NULL,
  platform TEXT,
  price REAL,
  status TEXT DEFAULT 'completed',
  purchased_at INTEGER DEFAULT (unixepoch('now'))
);

CREATE TABLE IF NOT EXISTS sponsored_impressions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sponsored_id INTEGER NOT NULL,
  user_id TEXT,
  viewed_at INTEGER DEFAULT (unixepoch('now'))
);

CREATE TABLE IF NOT EXISTS sponsored_clicks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sponsored_id INTEGER NOT NULL,
  user_id TEXT,
  clicked_at INTEGER DEFAULT (unixepoch('now'))
);

-- 7. Gamification System
CREATE TABLE IF NOT EXISTS achievements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  points INTEGER DEFAULT 10,
  type TEXT,
  requirement INTEGER,
  enabled BOOLEAN DEFAULT 1
);

CREATE TABLE IF NOT EXISTS user_achievements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  achievement_id INTEGER NOT NULL,
  progress INTEGER DEFAULT 0,
  unlocked BOOLEAN DEFAULT 0,
  unlocked_at INTEGER,
  UNIQUE(user_id, achievement_id)
);

CREATE TABLE IF NOT EXISTS user_points (
  user_id TEXT PRIMARY KEY,
  total_points INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  updated_at INTEGER DEFAULT (unixepoch('now'))
);

-- Insert Initial Config
INSERT OR IGNORE INTO app_config (key, value, description, updated_at) VALUES 
('min_version_android', '1.0.0', 'Minimum Android version required', strftime('%s', 'now')),
('min_version_ios', '1.0.0', 'Minimum iOS version required', strftime('%s', 'now')),
('maintenance_mode', 'false', 'Enable maintenance mode', strftime('%s', 'now')),
('ads_master_enabled', 'true', 'Master switch for all ads', strftime('%s', 'now')),
('feature_dosage_calculator', 'true', 'Enable Dosage Calculator feature', strftime('%s', 'now')),
('feature_drug_interactions', 'true', 'Enable Drug Interactions feature', strftime('%s', 'now')),
('feature_offline_mode', 'true', 'Enable Offline Mode feature', strftime('%s', 'now'));
