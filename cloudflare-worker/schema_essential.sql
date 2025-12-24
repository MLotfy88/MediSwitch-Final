-- Essential tables for Admin Dashboard functionality
-- Simple version for immediate deployment

-- Users table (simplified)
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  status TEXT DEFAULT 'active',
  created_at INTEGER DEFAULT (unixepoch('now')),
  updated_at INTEGER DEFAULT (unixepoch('now')),
  last_login INTEGER
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);

-- Subscriptions table (simplified)
CREATE TABLE IF NOT EXISTS subscriptions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  tier TEXT DEFAULT 'free' CHECK(tier IN ('free', 'premium')),
  platform TEXT,
  transaction_id TEXT UNIQUE,
  starts_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  status TEXT DEFAULT 'active' CHECK(status IN ('active', 'canceled', 'expired', 'trial')),
  auto_renew INTEGER DEFAULT 1,
  created_at INTEGER DEFAULT (unixepoch('now')),
  updated_at INTEGER DEFAULT (unixepoch('now'))
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_expires ON subscriptions(expires_at);

-- Sponsored drugs table
CREATE TABLE IF NOT EXISTS sponsored_drugs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  drug_id INTEGER NOT NULL,
  drug_name TEXT NOT NULL,
  priority INTEGER DEFAULT 1,
  active INTEGER DEFAULT 1,
  expires_at INTEGER,
  created_at INTEGER DEFAULT (unixepoch('now')),
  updated_at INTEGER DEFAULT (unixepoch('now'))
);

-- Notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'info',
  user_id TEXT,
  target_audience TEXT DEFAULT 'all',
  sent_at INTEGER DEFAULT (unixepoch('now')),
  created_at INTEGER DEFAULT (unixepoch('now'))
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_sent ON notifications(sent_at);

-- Feedback table
CREATE TABLE IF NOT EXISTS feedback (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT,
  name TEXT,
  email TEXT,
  subject TEXT,
  message TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'reviewed', 'resolved')),
  created_at INTEGER DEFAULT (unixepoch('now')),
  updated_at INTEGER DEFAULT (unixepoch('now'))
);

CREATE INDEX IF NOT EXISTS idx_feedback_status ON feedback(status);
CREATE INDEX IF NOT EXISTS idx_feedback_user ON feedback(user_id);

-- IAP Products table
CREATE TABLE IF NOT EXISTS iap_products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  price TEXT NOT NULL,
  currency TEXT DEFAULT 'EGP',
  active INTEGER DEFAULT 1,
  created_at INTEGER DEFAULT (unixepoch('now')),
  updated_at INTEGER DEFAULT (unixepoch('now'))
);
