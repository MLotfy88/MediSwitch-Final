-- Final Schema Alignment with Source Assets (v3)

-- 1. DRUGS Table Alignment
ALTER TABLE drugs ADD COLUMN qr_code TEXT;

-- 2. DRUG INTERACTIONS Table Alignment
-- SQLite doesn't support adding multiple columns in one go via ALTER TABLE
ALTER TABLE drug_interactions ADD COLUMN type TEXT;
ALTER TABLE drug_interactions ADD COLUMN arabic_effect TEXT;
ALTER TABLE drug_interactions ADD COLUMN recommendation TEXT;
ALTER TABLE drug_interactions ADD COLUMN arabic_recommendation TEXT;

-- 3. FOOD INTERACTIONS Table Alignment
-- Recreating to match source asset exactly: med_id, trade_name, interaction, source
DROP TABLE IF EXISTS food_interactions;
CREATE TABLE food_interactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    med_id INTEGER NOT NULL,
    trade_name TEXT,
    interaction TEXT NOT NULL,
    source TEXT DEFAULT 'DrugBank',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. DOSAGE GUIDELINES Table Alignment
-- Recreating to match source asset exactly: med_id, dailymed_setid, min_dose, max_dose, frequency, duration, instructions, condition, source, is_pediatric
DROP TABLE IF EXISTS med_dosages; -- Old name
DROP TABLE IF EXISTS dosage_guidelines; -- Aligned name
CREATE TABLE dosage_guidelines (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    med_id INTEGER NOT NULL,
    dailymed_setid TEXT,
    min_dose REAL,
    max_dose REAL,
    frequency INTEGER,
    duration INTEGER,
    instructions TEXT,
    condition TEXT,
    source TEXT,
    is_pediatric BOOLEAN,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
