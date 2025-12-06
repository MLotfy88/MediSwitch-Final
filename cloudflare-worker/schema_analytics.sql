-- Analytics Daily Stats (For Charts & Graphs)
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

CREATE INDEX IF NOT EXISTS idx_analytics_date ON analytics_daily(date);

-- Drug Views (For Trending)
CREATE TABLE IF NOT EXISTS drug_views (
  drug_id TEXT NOT NULL,
  view_count INTEGER DEFAULT 1,
  last_viewed_at INTEGER,
  PRIMARY KEY (drug_id)
);

CREATE INDEX IF NOT EXISTS idx_drug_views_count ON drug_views(view_count);

-- Initial Mock Data for Charts (To allow seeing something immediately, but stored in DB)
-- We will insert last 7 days with zeros or random legit data if preferred, but let's stick to structure.
-- The app logic will increment these counters.
