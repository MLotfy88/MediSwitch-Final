-- D1 Database Schema Migration
-- Purpose: Add DailyMed tracking and missing columns to existing tables
-- Run via: npx wrangler d1 execute mediswitch-db --file=d1_schema_migration.sql --remote

-- ========================================
-- 1. UPDATE drugs TABLE
-- ========================================
-- Add missing columns from scraped data

-- Check and add pharmacology column
ALTER TABLE drugs ADD COLUMN pharmacology TEXT;

-- Check and add barcode column
ALTER TABLE drugs ADD COLUMN barcode TEXT;

-- Note: SQLite doesn't support DROP COLUMN, but we can leave 'description' as-is
-- The scripts will simply not populate it anymore


-- ========================================
-- 2. UPDATE med_dosages TABLE
-- ========================================
-- Add DailyMed tracking columns

ALTER TABLE med_dosages ADD COLUMN dailymed_setid TEXT;
ALTER TABLE med_dosages ADD COLUMN dailymed_product_name TEXT;
ALTER TABLE med_dosages ADD COLUMN matching_confidence REAL DEFAULT 0.0;

-- Create index for DailyMed lookups
CREATE INDEX IF NOT EXISTS idx_med_dosages_dailymed ON med_dosages(dailymed_setid);


-- ========================================
-- 3. UPDATE drug_interactions TABLE
-- ========================================
-- Add drug ID tracking columns for both ingredients

ALTER TABLE drug_interactions ADD COLUMN egyptian_drug_id1 TEXT;
ALTER TABLE drug_interactions ADD COLUMN egyptian_drug_id2 TEXT;
ALTER TABLE drug_interactions ADD COLUMN dailymed_setid1 TEXT;
ALTER TABLE drug_interactions ADD COLUMN dailymed_setid2 TEXT;
ALTER TABLE drug_interactions ADD COLUMN mechanism TEXT;
ALTER TABLE drug_interactions ADD COLUMN clinical_significance TEXT;
ALTER TABLE drug_interactions ADD COLUMN confidence_score REAL DEFAULT 50.0;
ALTER TABLE drug_interactions ADD COLUMN last_verified TIMESTAMP;

-- Create indexes for drug ID lookups
CREATE INDEX IF NOT EXISTS idx_interactions_eg_drug1 ON drug_interactions(egyptian_drug_id1);
CREATE INDEX IF NOT EXISTS idx_interactions_eg_drug2 ON drug_interactions(egyptian_drug_id2);
CREATE INDEX IF NOT EXISTS idx_interactions_dm_setid1 ON drug_interactions(dailymed_setid1);
CREATE INDEX IF NOT EXISTS idx_interactions_dm_setid2 ON drug_interactions(dailymed_setid2);


-- ========================================
-- 4. VERIFICATION
-- ========================================
-- Query to verify changes (run separately after migration)
-- SELECT sql FROM sqlite_master WHERE type='table' AND name IN ('drugs', 'med_dosages', 'drug_interactions');
