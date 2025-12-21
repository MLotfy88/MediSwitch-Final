-- Cloudflare D1 Schema Update
-- Add pharmacology columns to drugs table and create food_interactions table

-- Step 1: Add pharmacology columns to drugs table
ALTER TABLE drugs ADD COLUMN indication TEXT;
ALTER TABLE drugs ADD COLUMN mechanism_of_action TEXT;
ALTER TABLE drugs ADD COLUMN pharmacodynamics TEXT;
ALTER TABLE drugs ADD COLUMN data_source_pharmacology TEXT;

-- Step 2: Create food_interactions table
CREATE TABLE IF NOT EXISTS food_interactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    med_id INTEGER NOT NULL,
    interaction_text TEXT NOT NULL,
    source TEXT DEFAULT 'DrugBank',
    created_at INTEGER DEFAULT (strftime('%s', 'now')),
    FOREIGN KEY (med_id) REFERENCES drugs(id) ON DELETE CASCADE
);

-- Step 3: Create index for food_interactions
CREATE INDEX IF NOT EXISTS idx_food_interactions_med_id ON food_interactions(med_id);
