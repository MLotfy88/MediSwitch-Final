-- migration_v2.sql
-- 1. Update Drugs table
ALTER TABLE drugs ADD COLUMN old_price REAL DEFAULT NULL;

-- 2. Create Analytics Daily Table
CREATE TABLE IF NOT EXISTS analytics_daily (
  date TEXT PRIMARY KEY,
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

-- 3. Create Monetization Tables
CREATE TABLE IF NOT EXISTS subscriptions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  tier TEXT CHECK(tier IN ('free', 'premium', 'premium_plus')),
  platform TEXT CHECK(platform IN ('android', 'ios', 'web')),
  transaction_id TEXT UNIQUE,
  starts_at INTEGER,
  expires_at INTEGER,
  status TEXT DEFAULT 'active' CHECK(status IN ('active', 'canceled', 'expired', 'trial')),
  auto_renew BOOLEAN DEFAULT 1,
  price REAL,
  created_at INTEGER DEFAULT (unixepoch('now')),
  updated_at INTEGER DEFAULT (unixepoch('now'))
);

CREATE TABLE IF NOT EXISTS iap_products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  name_ar TEXT,
  price REAL NOT NULL,
  currency TEXT DEFAULT 'USD',
  type TEXT CHECK(type IN ('consumable', 'non_consumable', 'subscription')),
  enabled BOOLEAN DEFAULT 1,
  sort_order INTEGER DEFAULT 0,
  created_at INTEGER DEFAULT (unixepoch('now'))
);

CREATE TABLE IF NOT EXISTS sponsored_drugs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  drug_id INTEGER NOT NULL,
  drug_name TEXT NOT NULL,
  priority INTEGER DEFAULT 1,
  active BOOLEAN DEFAULT 1,
  starts_at INTEGER,
  expires_at INTEGER,
  created_at INTEGER DEFAULT (unixepoch('now')),
  updated_at INTEGER DEFAULT (unixepoch('now'))
);

CREATE TABLE IF NOT EXISTS missed_searches (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  query TEXT NOT NULL,
  hit_count INTEGER DEFAULT 1,
  last_searched_at INTEGER DEFAULT (unixepoch('now'))
);
