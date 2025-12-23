-- migration_v3.sql
-- Aligning Monetzation Tables with Worker Logic

-- 1. Drop and Recreate Sponsored Drugs with full metadata support
DROP TABLE IF EXISTS sponsored_drugs;
CREATE TABLE sponsored_drugs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  drug_id INTEGER NOT NULL,
  company TEXT,
  banner_url TEXT,
  campaign_type TEXT DEFAULT 'search_top',
  priority INTEGER DEFAULT 0,
  status TEXT DEFAULT 'active',
  starts_at INTEGER,
  ends_at INTEGER,
  created_at INTEGER DEFAULT (unixepoch('now')),
  updated_at INTEGER DEFAULT (unixepoch('now'))
);

-- 2. Drop and Recreate IAP Products with tier and pricing support
DROP TABLE IF EXISTS iap_products;
CREATE TABLE iap_products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id TEXT UNIQUE NOT NULL,
  tier TEXT DEFAULT 'premium',
  name TEXT NOT NULL,
  description TEXT,
  price REAL NOT NULL,
  currency TEXT DEFAULT 'EGP',
  duration_days INTEGER DEFAULT 30,
  status TEXT DEFAULT 'active',
  created_at INTEGER DEFAULT (unixepoch('now'))
);

-- 3. Ensure User Feedback table exists (just in case)
CREATE TABLE IF NOT EXISTS user_feedback (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT,
  name TEXT,
  email TEXT,
  subject TEXT,
  message TEXT NOT NULL,
  status TEXT DEFAULT 'new',
  created_at INTEGER DEFAULT (unixepoch('now'))
);
