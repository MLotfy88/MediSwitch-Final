
DROP TABLE IF EXISTS drugs;

CREATE TABLE IF NOT EXISTS drugs (
    id INTEGER PRIMARY KEY,
    trade_name TEXT,
    arabic_name TEXT,
    old_price TEXT,
    price TEXT,
    active TEXT,
    company TEXT,
    dosage_form TEXT,
    dosage_form_ar TEXT,
    unit TEXT,
    description TEXT,
    category TEXT,
    pharmacology TEXT,
    category_ar TEXT,
    size INTEGER,
    last_update TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

