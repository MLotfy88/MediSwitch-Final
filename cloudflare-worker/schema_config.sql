-- Application Configuration Table (Key-Value Store)
CREATE TABLE IF NOT EXISTS app_config (
  key TEXT PRIMARY KEY,
  value TEXT,
  description TEXT,
  updated_at INTEGER
);

-- Missed Searches (Analytics)
CREATE TABLE IF NOT EXISTS missed_searches (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  query TEXT NOT NULL,
  count INTEGER DEFAULT 1,
  last_seen_at INTEGER,
  created_at INTEGER
);

CREATE INDEX IF NOT EXISTS idx_missed_searches_query ON missed_searches(query);
CREATE INDEX IF NOT EXISTS idx_missed_searches_last_seen ON missed_searches(last_seen_at);

-- Initial Default Config
INSERT OR IGNORE INTO app_config (key, value, description, updated_at) VALUES 
('min_version_android', '1.0.0', 'Minimum Android version required', strftime('%s', 'now')),
('min_version_ios', '1.0.0', 'Minimum iOS version required', strftime('%s', 'now')),
('maintenance_mode', 'false', 'Enable maintenance mode', strftime('%s', 'now')),
('contact_email', 'support@mediswitch.com', 'Support email address', strftime('%s', 'now')),
('ad_banner_id', '', 'AdMob Banner ID', strftime('%s', 'now')),
('ad_interstitial_id', '', 'AdMob Interstitial ID', strftime('%s', 'now')),
('ad_interstitial_frequency', '5', 'Frequency of interstitial ads (clicks)', strftime('%s', 'now')),
('feature_dosage_calculator', 'true', 'Enable Dosage Calculator feature', strftime('%s', 'now')),
('feature_drug_interactions', 'true', 'Enable Drug Interactions feature', strftime('%s', 'now')),
('feature_favorites_list', 'true', 'Enable Favorites List feature', strftime('%s', 'now')),
('feature_offline_mode', 'true', 'Enable Offline Mode feature', strftime('%s', 'now'));
