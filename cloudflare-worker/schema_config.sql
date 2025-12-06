-- App Configuration Table
CREATE TABLE IF NOT EXISTS app_config (
    key TEXT PRIMARY KEY,
    value TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed defaults (AdMob IDs)
INSERT OR IGNORE INTO app_config (key, value) VALUES ('ad_banner_id', 'ca-app-pub-3940256099942544/6300978111');
INSERT OR IGNORE INTO app_config (key, value) VALUES ('ad_interstitial_id', 'ca-app-pub-3940256099942544/1033173712');
INSERT OR IGNORE INTO app_config (key, value) VALUES ('enable_premium_features', 'false');
INSERT OR IGNORE INTO app_config (key, value) VALUES ('maintenance_mode', 'false');

-- Missed Searches Analytics
CREATE TABLE IF NOT EXISTS missed_searches (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    term TEXT NOT NULL,
    count INTEGER DEFAULT 1,
    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_missed_searches_last_seen ON missed_searches(last_seen);

