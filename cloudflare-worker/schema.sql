-- MediSwitch D1 Database Schema
-- SQLite database for drug information

CREATE TABLE IF NOT EXISTS drugs (
    id INTEGER PRIMARY KEY,
    trade_name TEXT NOT NULL,
    arabic_name TEXT,
    old_price REAL,
    price REAL,
    active TEXT,
    main_category TEXT,
    main_category_ar TEXT,
    category TEXT,
    category_ar TEXT,
    company TEXT,
    dosage_form TEXT,
    dosage_form_ar TEXT,
    unit TEXT DEFAULT '1',
    usage TEXT,
    usage_ar TEXT,
    description TEXT,
    last_price_update TEXT,
    concentration TEXT,
    visits INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for fast queries
CREATE INDEX IF NOT EXISTS idx_trade_name ON drugs(trade_name);
CREATE INDEX IF NOT EXISTS idx_company ON drugs(company);
CREATE INDEX IF NOT EXISTS idx_category ON drugs(main_category);
CREATE INDEX IF NOT EXISTS idx_updated_at ON drugs(updated_at);
CREATE INDEX IF NOT EXISTS idx_last_price_update ON drugs(last_price_update);

-- Full-text search (for future)
-- CREATE VIRTUAL TABLE drugs_fts USING fts5(trade_name, arabic_name, active, company);
