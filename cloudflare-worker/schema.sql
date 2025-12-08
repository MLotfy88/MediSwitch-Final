-- D1 Database Schema Creation
-- Run this to set up required tables for MediSwitch Worker

-- Dosage Guidelines Table
CREATE TABLE IF NOT EXISTS dosage_guidelines (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  active_ingredient TEXT NOT NULL,
  strength TEXT NOT NULL,
  standard_dose TEXT,
  max_dose TEXT,
  package_label TEXT,
  source TEXT DEFAULT 'OpenFDA',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_dosage_ingredient ON dosage_guidelines(active_ingredient);
CREATE INDEX IF NOT EXISTS idx_dosage_strength ON dosage_guidelines(strength);

-- Configuration Table
CREATE TABLE IF NOT EXISTS config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default config values
INSERT OR IGNORE INTO config (key, value) VALUES ('ads_enabled', 'true');
INSERT OR IGNORE INTO config (key, value) VALUES ('test_ads_enabled', 'false');
INSERT OR IGNORE INTO config (key, value) VALUES ('app_version', '1.0.0');
