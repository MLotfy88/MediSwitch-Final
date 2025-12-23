-- Migration to fix column names and mapping
-- 1. Rename last_update to last_price_update
-- 2. Ensure usage maps to description and units maps to unit

-- In SQLite (D1), renaming a column is supported via ALTER TABLE
ALTER TABLE drugs RENAME COLUMN last_update TO last_price_update;
