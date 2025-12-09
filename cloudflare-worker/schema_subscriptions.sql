-- Subscriptions Table
CREATE TABLE IF NOT EXISTS subscriptions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  tier TEXT CHECK(tier IN ('free', 'premium')),
  platform TEXT,
  transaction_id TEXT UNIQUE,
  starts_at INTEGER,
  expires_at INTEGER,
  status TEXT DEFAULT 'active' CHECK(status IN ('active', 'canceled', 'expired', 'trial')),
  auto_renew BOOLEAN DEFAULT 1,
  price REAL,
  created_at INTEGER DEFAULT (unixepoch('now')),
  updated_at INTEGER DEFAULT (unixepoch('now'))
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_expires ON subscriptions(expires_at);
