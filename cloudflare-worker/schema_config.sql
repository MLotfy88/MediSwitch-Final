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
-- App Version Control
('min_version_android', '1.0.0', 'Minimum Android version required', strftime('%s', 'now')),
('min_version_ios', '1.0.0', 'Minimum iOS version required', strftime('%s', 'now')),
('maintenance_mode', 'false', 'Enable maintenance mode', strftime('%s', 'now')),
('contact_email', 'support@mediswitch.com', 'Support email address', strftime('%s', 'now')),

-- AdMob App IDs
('admob_app_id_android', '', 'AdMob App ID for Android', strftime('%s', 'now')),
('admob_app_id_ios', '', 'AdMob App ID for iOS', strftime('%s', 'now')),

-- Banner Ad Units
('banner_ad_unit_id_android', '', 'Banner Ad Unit ID (Android)', strftime('%s', 'now')),
('banner_ad_unit_id_ios', '', 'Banner Ad Unit ID (iOS)', strftime('%s', 'now')),

-- Interstitial Ad Units  
('interstitial_ad_unit_id_android', '', 'Interstitial Ad Unit ID (Android)', strftime('%s', 'now')),
('interstitial_ad_unit_id_ios', '', 'Interstitial Ad Unit ID (iOS)', strftime('%s', 'now')),

-- Rewarded Ad Units (Future)
('rewarded_ad_unit_id_android', '', 'Rewarded Ad Unit ID (Android)', strftime('%s', 'now')),
('rewarded_ad_unit_id_ios', '', 'Rewarded Ad Unit ID (iOS)', strftime('%s', 'now')),

-- Native Ad Units (Future)
('native_ad_unit_id_android', '', 'Native Ad Unit ID (Android)', strftime('%s', 'now')),
('native_ad_unit_id_ios', '', 'Native Ad Unit ID (iOS)', strftime('%s', 'now')),

-- Master Ad Control
('ads_master_enabled', 'true', 'Master switch for all ads', strftime('%s', 'now')),
('test_ads_enabled', 'false', 'Use test ads globally', strftime('%s', 'now')),

-- Ad Type Toggles
('banner_enabled', 'true', 'Enable Banner Ads', strftime('%s', 'now')),
('banner_test_mode', 'false', 'Banner Test Mode', strftime('%s', 'now')),
('interstitial_enabled', 'true', 'Enable Interstitial Ads', strftime('%s', 'now')),
('interstitial_test_mode', 'false', 'Interstitial Test Mode', strftime('%s', 'now')),
('rewarded_enabled', 'false', 'Enable Rewarded Ads', strftime('%s', 'now')),
('rewarded_test_mode', 'false', 'Rewarded Test Mode', strftime('%s', 'now')),
('native_enabled', 'false', 'Enable Native Ads', strftime('%s', 'now')),
('native_test_mode', 'false', 'Native Test Mode', strftime('%s', 'now')),

-- Placement Controls
('ad_placement_home_bottom', 'true', 'Banner at Home Bottom', strftime('%s', 'now')),
('ad_placement_search_bottom', 'true', 'Banner at Search Bottom', strftime('%s', 'now')),
('ad_placement_drug_details_bottom', 'true', 'Banner at Drug Details Bottom', strftime('%s', 'now')),
('ad_placement_between_search_results', 'false', 'Ads Between Search Results', strftime('%s', 'now')),
('ad_placement_between_alternatives', 'false', 'Ads Between Alternatives', strftime('%s', 'now')),

-- Ad Frequency & Timing
('interstitial_ad_frequency', '10', 'Show interstitial every N actions', strftime('%s', 'now')),
('banner_refresh_rate', '60', 'Banner refresh rate in seconds', strftime('%s', 'now')),

-- Features
('feature_dosage_calculator', 'true', 'Enable Dosage Calculator feature', strftime('%s', 'now')),
('feature_drug_interactions', 'true', 'Enable Drug Interactions feature', strftime('%s', 'now')),
('feature_favorites_list', 'true', 'Enable Favorites List feature', strftime('%s', 'now')),
('feature_offline_mode', 'true', 'Enable Offline Mode feature', strftime('%s', 'now'));

