-- MediSwitch D1 Database Import (Full Sync)
-- Total records: 25491
-- Generated from local assets/meds.csv
DROP TABLE IF EXISTS drugs;
CREATE TABLE drugs (
  id INTEGER PRIMARY KEY,
  trade_name TEXT,
  arabic_name TEXT,
  price TEXT,
  old_price TEXT,
  active TEXT,
  company TEXT,
  dosage_form TEXT,
  dosage_form_ar TEXT,
  usage TEXT,
  category TEXT,
  concentration TEXT,
  pharmacology TEXT,
  barcode TEXT,
  unit TEXT,
  visits INTEGER DEFAULT 0,
  last_price_update TEXT,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);